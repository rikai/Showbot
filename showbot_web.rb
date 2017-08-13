# showbot_web.rb
# The web front-end for showbot

# Gems
require 'bundler/setup'
require 'coffee_script'
require 'sinatra' unless defined?(Sinatra)
require 'sinatra/reloader' if development?
require 'sinatra-websocket'

require 'json'

require File.join(File.dirname(__FILE__), 'environment')


SHOWS_JSON = File.expand_path(File.join(File.dirname(__FILE__), "public", "shows.json")) unless defined? SHOWS_JSON

class ShowbotWeb < Sinatra::Base
  set :open_sockets, {}

  configure do
    set :public_folder, "#{File.dirname(__FILE__)}/public"
    set :views, "#{File.dirname(__FILE__)}/views"
    set :shows, Shows.new(JSON.parse(File.open(SHOWS_JSON).read)["shows"])
    set :live_mode_enabled, ENV['LIVE_MODE'] == "true"
    set :socket_key_id_enabled, ENV['SOCKET_KEY_ID'] == "true"
  end

  configure(:production, :development) do
    enable :logging
  end

  configure :development do
    register Sinatra::Reloader
  end

  # ------------------
  # Pages
  # ------------------

  # CoffeeScript
  get '/js/showbot.js' do
    coffee :'coffeescripts/showbot'
  end

  get '/' do
    @title = "Home"
    suggestion_sets = Suggestion.recent.group_by_show
    view_mode = params[:view_mode] || 'tables'
    haml :index, :locals => {suggestion_sets: suggestion_sets, :view_mode => view_mode}
  end

  get '/titles' do
    @title = "Title Suggestions in the last 24 hours"
    view_mode = params[:view_mode] || 'tables'
    suggestion_sets = Suggestion.recent.group_by_show
    if view_mode == 'hacker'
      content_type 'text/plain'
      haml :'suggestion/hacker_mode', :locals => {suggestion_sets: suggestion_sets, :view_mode => view_mode}, :layout => false
    else
      haml :'suggestion/index', :locals => {suggestion_sets: suggestion_sets, :view_mode => view_mode}
    end
  end

  get '/new_title_trigger' do
    title_id = params[:id]
    self.broadcast_new_title(title_id)
  end

  get '/links' do
    @title = "Suggested Links in the last 24 hours"
    @links = Link.recent.all(:order => [:created_at.desc])
    haml :links
  end

  get '/all' do
    suggestion_sets = Suggestion.all(:order => [:created_at.desc]).group_by_show
    content_type 'text/plain'
    haml :'suggestion/hacker_mode', :locals => {suggestion_sets: suggestion_sets}, :layout => false
  end

  get '/titles/:id/vote_up' do
    content_type :json
    # Only allow XHR requests for voting
    if request.xhr?
      suggestion = Suggestion.get(params[:id])
      cluster_top = suggestion.top_of_cluster? # figure out if top before adding new vote
      suggestion.vote_up(request.ip)
      response = {
        suggestion_id: suggestion.id,
        votes: suggestion.votes.count.to_s,
        cluster_top: cluster_top,
        cluster_id: suggestion.cluster_id,
        cluster_votes: suggestion.total_for_cluster
      }
      self.broadcast_upvote(request, response)
      response.to_json
    else
      redirect '/'
    end
  end

  # Word cloud generation
  get '/clouds_between/:days_a/:days_b' do
    days_ago = [params[:days_a].to_i, params[:days_b].to_i].sort
    suggestion_sets = Suggestion.all(:created_at => ( (DateTime.now - days_ago[1])..(DateTime.now - days_ago[0]) ), :order => [:created_at.desc]).group_by_show
    haml :'clouds', :locals => { cloud_data: WordCount.generate_clouds(suggestion_sets) }
  end

  get '/cloud_svg/:year/:month/:day/:index' do
    the_date = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    bracketed_suggestion_sets = Suggestion.all(:created_at => ( (the_date - 1)..(the_date + 2) ), :order => [:created_at.desc]).group_by_show
    suggestion_sets = bracketed_suggestion_sets.select { |set| set.suggestions[0].created_at.to_date == the_date.to_date }

    haml :'clouds_svg', :locals => { cloud_data: WordCount.generate_clouds(suggestion_sets), cloud_index: params[:index].to_i }
  end

  get '/num_clouds_on_date/:year/:month/:day' do
    content_type :json

    the_date = DateTime.new(params[:year].to_i, params[:month].to_i, params[:day].to_i)
    bracketed_suggestion_sets = Suggestion.all(:created_at => ( (the_date - 1)..(the_date + 2) ), :order => [:created_at.desc]).group_by_show

    { num_clouds: bracketed_suggestion_sets.select { |set| set.suggestions[0].created_at.to_date == the_date.to_date }.count }.to_json
  end

  # ------------------
  # API
  # ------------------

  # Creates a title suggestion based on a POST request with valid
  # title and user parameters.
  #
  # title   - String less than 40 characters.
  # user    - String username to use.
  # api_key - Your API key.
  #
  # Examples
  #
  #   Context: Posting a valid show title with a valid user.
  #   POST /suggestions/new
  #   params: {
  #     title: 'Omg Title',
  #     user: 'mrman',
  #     api_key: 'keyhere'
  #   }
  #
  #   Response:
  #   {
  #     suggestion: {
  #       user: 'mrman',
  #       title: 'Omg Title'
  #     }
  #   }
  #
  #   Context: Posting a show title that's too long.
  #   POST /suggestions/new
  #   params: {
  #     title: 'Super freaking long title that will make showbot cry.',
  #     user: 'badman',
  #     api_key: 'keyhere'
  #   }
  #
  #   Response:
  #   {
  #     error: 'That suggestion was too long. Showbot is sorry. Think title,
  #             not transcript.'
  #   }
  #
  #   Context: The same title suggested seconds later.
  #   POST /suggestions/new
  #   params: {
  #     title: 'Same Title',
  #     user: 'slowpoke',
  #     api_key: 'keyhere'
  #   }
  #
  #   Response:
  #   {
  #     error: 'Darn, fastman beat you to "Same Title".'
  #   }
  #
  # Returns a JSON response with the original suggestion and an error
  # message if one was generated.
  post '/suggestions/new' do
    content_type :json

    api_key = params[:api_key]
    response = nil
    if api_key and ApiKey.first(value: api_key)
      title = params[:title]
      user = params[:user]
      if title && user
        suggestion = Suggestion.create(
          title: title,
          user: user
        )

        if suggestion.saved?
          response = {
            suggestion: {
              title: title,
              user: user
            }
          }
        else
          response = {
            error: suggestion.errors.first.first
          }
        end
      else
        if !title
          response = {
            error: 'Missing / Invalid Title'
          }
        else
          response = {
            error: 'Missing / Invalid User'
          }
        end
      end
    end

    if response
      response.to_json
    else
      halt 404, {
       error: "Invalid Api Key #{api_key}"
      }.to_json
    end
  end

  # ------------------
  # Sockets
  # ------------------
  #
  def broadcast_upvote(request, response)
    logger.info "Broadcasting to all connected sockets aside from #{request.ip}"

    response['action'] = 'upvote'
    EM.next_tick do
      settings.open_sockets.each do |k,v|
        if k == request.ip then next else v.send(response.to_json) end
      end
    end
  end

  def broadcast_new_title(title_id)
    suggestion = Suggestion.get(title_id)

    cluster = {
      id: nil,
      render: self.cluster_live_render(suggestion, request),
      new_cluster: nil
    }

    if suggestion.in_cluster?
      sgs = suggestion.cluster.suggestions
      cluster[:id] = suggestion.cluster.id
      if(sgs.length == 2)
        cluster[:new_cluster] = {
          orig_sg_id: sgs.select{|sg| sg.id != suggestion.id}.first.id
        }
      end
    end

    response = {
      action: 'new_title',
      show_slug: suggestion.show,
      trl: self.trl_render(suggestion),
      bubble_live: self.bubble_live_render(suggestion, request),
      cluster: cluster
    }

    EM.next_tick do
      settings.open_sockets.each do |k,v|
        v.send(response.to_json)
      end
    end
  end


  def timeago_render(created_at)
    timeago_engine = Haml::Engine.new(File.read(
      "#{File.dirname(__FILE__)}/views/suggestion/_timeago.haml"))
    timeago_engine.render(self, {
      datetime: created_at
    })
  end

  def trl_render(suggestion)
    trl_engine = Haml::Engine.new(File.read(
      "#{File.dirname(__FILE__)}/views/suggestion/_table_row_live.haml"))
    trl_engine.render(self, {
      suggestion: suggestion,
      timeago: timeago_render(suggestion.created_at)
    })
  end

  def bubble_live_render(suggestion, request)
    bubble_engine = Haml::Engine.new(File.read(
      "#{File.dirname(__FILE__)}/views/suggestion/_bubble_live.haml"))
    bubble_engine.render(self, {
      suggestion: suggestion,
      timeago: timeago_render(suggestion.created_at),
      request: request
    })
  end

  def cluster_live_render(suggestion, request)
    cluster_engine = Haml::Engine.new(File.read(
      "#{File.dirname(__FILE__)}/views/suggestion/live_cluster/_cluster.haml"))
    cluster_engine.render(self, {
      suggestion: suggestion,
      cluster: self.cluster_struct_for_suggestion(suggestion, request)
    })
  end

  def cluster_struct_for_suggestion(suggestion, request)
    if suggestion.in_cluster?
      suggestion.cluster.suggestions
        .map do |sg|
          {
            suggestion: sg,
            belongs_to_cluster: true,
            is_top: sg.top_of_cluster?,
            render: self.live_cluster_row_render(sg, request)
          }
        end
        .sort{|lhs, rhs| lhs[:is_top] ? -1 : 1} # Ensure top item is first row
    else
      [{
        suggestion: suggestion,
        belongs_to_cluster: false,
        is_top: true,
        render: self.live_cluster_row_render(suggestion, request)
      }]
    end
  end

  def live_cluster_row_render(suggestion, request)
    cluster_row_engine = Haml::Engine.new(File.read(
      "#{File.dirname(__FILE__)}/views/suggestion/live_cluster/_cluster_table_row.haml"))
    cluster_row_engine.render(self, {
      timeago: timeago_render(suggestion.created_at),
      suggestion: suggestion,
      request: request
    })
  end

  get '/socket' do
    if !request.websocket?
      # Bad request, should hit this endpoint unless it's a websocket request
      status 400
    else
      request.websocket do |ws|
        socket_key = settings.socket_key_id_enabled ?
          request.env["HTTP_SEC_WEBSOCKET_KEY"] : request.ip

        ws.onopen do
          # Add client to manifest

          if settings.open_sockets.key?(socket_key)
            # NOTE: Need to protect against cases where we receive an onopen event
            # and attempt to register a client with a key that already exists in
            # our open socket manifest. If we just clober the entry without closing
            # the socket, we leak the original handle. This allows the originally
            # connected client to emit a close event and actuall disconnect the
            # second client that connected. If we force close it, the original client
            # cannot force all connections sharing it's key shut.
            settings.open_sockets[socket_key].close_websocket
          end

          settings.open_sockets[socket_key] = ws
        end

        ws.onclose do
          # Cleanup after client disconnects
          settings.open_sockets.delete(socket_key)
        end

      end
    end
  end


  # ------------------
  # Helpers
  # ------------------

  helpers do
    include Rack::Utils
    alias_method :h, :escape_html

    def external_link(link)
      /^http/.match(link) ? link : "http://#{link}"
    end

    # Returns a string truncated in the middle
    # Note: Rounds max_length down to nearest even number
    def truncate_string(string, max_length)
      if string.length > max_length
        # +/- 2 is to account for the elipse in the middle
        "#{string[0..(max_length/2)-2]}...#{string[-(max_length/2)+2..-1]}"
      else
        string
      end
    end

    def show_title_for_slug(slug)
      text = "Show Not Listed"
      if slug
        text = Shows.find_show_title(slug)
      end
      text
    end

    def suggestion_set_hr(suggestion_set)
      html = ''
      html << "<h2 class='show_break'>"
      html << "#{show_title_for_slug(suggestion_set.slug)}</h2>"
    end

    def link_to_vote_up(suggestion)
      html = ''
      # onclick returns false to keep from allowing
      html << "<a href='#' class='vote_up' onclick='return false;' data-id='#{suggestion.id}'>"
      html <<   "<span class='vote_arrow'/>"
      html << "</a>"
    end

    def link_and_vote_count(suggestion, user_ip)
      html = ''
      extra_classes = []
      if suggestion.user_already_voted?(user_ip)
        extra_classes << 'voted'
      else
        html << link_to_vote_up(suggestion)
      end
      html << "<span class='vote_count #{extra_classes.join(',')}'>#{suggestion.votes_counter}</span>"
    end

    def development?
      settings.development?
    end

    def cloud_json(cloud_data)
      return if cloud_data.nil?

      cloud_data.map do |d|
        {
          title: "#{show_title_for_slug(d[:show])} #{d[:time].to_date.to_s}",
          data: d[:data]
        }
      end.to_json
    end

  end # helpers

end
