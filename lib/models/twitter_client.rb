begin
  require 'x'
  require 'htmlentities'
  require 'chronic_duration'
rescue LoadError
  # IRC-only gems not available in web-only mode
  return
end

module TwitterClient
  def self.new(config)
    users = convert_to_users_hash Array(config[:users])

    begin
      client = new_api_client(config)
      RealTwitterClient.new(client, users)
    rescue
      NilTwitterClient.new
    end
  end

  private

  def self.convert_to_users_hash(users_array)
    users_array.map { |user| [user, nil] }.to_h
  end

  def self.new_api_client(config)
    X::Client.new(
      api_key:             config[:consumer_key],
      api_key_secret:      config[:consumer_secret],
      access_token:        config[:access_token],
      access_token_secret: config[:access_token_secret]
    )
  end

  class RealTwitterClient
    def initialize(client, users)
      @entities  = HTMLEntities.new
      @statuses  = users   # { handle => TwitterStatus | nil }
      @user_ids  = {}      # cached { handle => twitter user id string }
      @client    = client
    end

    def user_names
      @statuses.keys
    end

    def valid_twitter_user?(user)
      comparable = as_comparable_handle(user)
      user_names.any? { |name| name.downcase == comparable }
    end

    def last_status_for(user)
      return nil unless valid_twitter_user?(user)
      @statuses[canonicalize_handle(user)]
    end

    def update_status_for(user)
      return false unless valid_twitter_user?(user)
      handle      = canonicalize_handle(user)
      last_status = @statuses[handle]

      user_id = fetch_user_id(handle)
      return false unless user_id

      response   = @client.get("users/#{user_id}/tweets?max_results=5&exclude=retweets,replies&tweet.fields=created_at,text")
      tweet_data = response.dig('data', 0)
      return false unless tweet_data

      new_status = TwitterStatus.new(handle, tweet_data, @entities)
      return false if last_status == new_status

      @statuses[handle] = new_status
      true
    end

    def update_all_statuses
      updated_users = []
      @statuses.keys.each do |user|
        updated_users << user if update_status_for(user)
      end
      updated_users
    end

    private

    def fetch_user_id(handle)
      return @user_ids[handle] if @user_ids[handle]
      response = @client.get("users/by/username/#{strip_at_sign(handle)}")
      user_id  = response.dig('data', 'id')
      @user_ids[handle] = user_id if user_id
      user_id
    end

    def strip_at_sign(handle)
      handle.start_with?('@') ? handle[1..] : handle
    end

    def as_comparable_handle(handle)
      strip_at_sign(handle.downcase)
    end

    def canonicalize_handle(handle)
      comparable = as_comparable_handle(handle)
      user_names.find { |name| name.downcase == comparable }
    end
  end

  class NilTwitterClient
    def user_names
      []
    end

    def valid_twitter_user?(user)
      false
    end

    def last_status_for(user)
      nil
    end

    def update_status_for(user)
      # no op
    end

    def update_all_statuses
      []
    end
  end

  class TwitterStatus
    attr_reader :handle
    alias_method :user, :handle

    def initialize(handle, api_status, htmlentities = HTMLEntities.new)
      @handle   = handle
      @status   = api_status  # Hash from Twitter API v2
      @entities = htmlentities
    end

    def id
      return nil if @status.nil?
      @status['id']
    end

    def posted_at
      return nil if @status.nil?
      DateTime.parse(@status['created_at'])
    end

    def text
      return '' if @status.nil?
      html_decode @status['text']
    end

    def ==(other_status)
      return true  if @status.nil? && other_status.nil?
      return false if @status.nil? || other_status.nil?
      id == other_status.id
    end

    def to_s
      return '' if @status.nil?
      seconds_ago = (Time.now - posted_at.to_time).to_i
      posted_ago  = ChronicDuration.output(seconds_ago, :format => :long)
      "@#{handle}: #{text} (#{posted_ago} ago)"
    end

    private

    def html_decode(text)
      text_decoded = nil
      until text == text_decoded
        text_decoded = text
        text = @entities.decode text
      end
      text
    end
  end
end
