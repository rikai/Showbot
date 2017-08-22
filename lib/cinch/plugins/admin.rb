# Admin commands for the bot

module Cinch
  module Plugins
    class Admin
      include Auth::AdminPlugin

      [{
        :pattern => /(?:exit|quit)/i,
        :method => :command_exit,
        :unauthorized_msg => 'You are not authorized to command the bot to exit.'
      }, {
        :pattern => /start_show$/i,
        :method => :command_show_list,
        :unauthorized_msg => 'You are not authorized to start a show.'
      }, {
        :pattern => /start_show\s+(.+)/i,
        :method => :command_start_show,
        :unauthorized_msg => 'You are not authorized to start a show.'
      }, {
        :pattern => /end_show/i,
        :method => :command_end_show,
        :unauthorized_msg => 'You are not authorized to end a show.'
      }, {
        :pattern => /join\s(.+)/i,
        :method => :command_join,
        :unauthorized_msg => 'You are not authorized to invite the bot.'
      }, {
        :pattern => /leave\s(.+)/i,
        :method => :command_leave,
        :unauthorized_msg => 'You are not authorized to make the bot leave.'
      }].each do |m|
        admin_match m[:pattern], {
          :method => m[:method],
          :unauthorized_msg => m[:unauthorized_msg]
        }
      end

      def initialize(*args)
        super *args
        @data_json = DataJSON.new config[:data_json]
        @shows = Shows.new(JSON.parse(File.open(SHOWS_JSON).read)["shows"])
      end

      def command_join(m, channel)
        Channel(channel).join
      end

      def command_leave(m, channel)
        Channel(channel).part
      end

      def command_show_list(m)
        shows = @shows.shows
        shows.each do |show|
          m.user.send "#{show.title}: !start_show #{show.url}"
        end
      end

      def command_start_show(m, show_slug)
        show = @shows.find_show show_slug
        if show.nil?
          m.user.send 'Sorry, but I couldn\'t find that particular show.'
          return
        end

        begin
          @data_json.start_show show

          bot.channels.each do |channel|
            channel.send "#{show.title} starts now!"
          end
        rescue IOError => err
          exception err
          m.user.send 'IO Error: Cannot persist data!'
        end
      end

      def command_end_show(m)
        if !@data_json.live?
          m.user.send 'No live show, but thanks for playing!'
          return
        end

        title = @data_json.title

        begin
          @data_json.end_show

          bot.channels.each do |channel|
            channel.send "Show's over, folks. Thanks for coming to #{title}!"
          end
        rescue IOError => err
          exception err
          m.user.send 'IO Error: Cannot persist data!'
        end
      end

      def command_exit(m)
        bot.channels.each do |channel|
          channel.send "#{shared[:Bot_Nick]} is shutting down. Good bye :("
        end
        Process.exit
      end
    end
  end
end

