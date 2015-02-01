# Report the number of linux games available on steam

require 'json'
require 'net/http'
require 'uri'

module Cinch
  module Plugins
    class LinuxGames
      include Cinch::Plugin

      match "help linuxgames",    :method => :command_help       # !help linuxgames
      match /(?:linuxgames|lg)/i, :method => :command_linuxgames # !linuxgames

      def initialize(*args)
        super

        @linuxgames_json_uri = URI.parse(config[:linuxgames_json_uri] || "https://raw.githubusercontent.com/SteamDatabase/SteamLinux/master/GAMES.json")
        @cache_time = config[:cache_time] || 60
        @cache_last_updated = nil
      end

      # Show help for the suggestions module
      def command_help(m)
        m.user.send "Usage: !linuxgames"
      end

      # Add the user's suggestion to the database
      def command_linuxgames(m)
        count = games_count

        if !count
          m.user.send("Can't reach the Steam database :( Please try again later")
        end

        msg = Format(nil, "At the moment there are %s linux games in the Steam store" % [Format(:italic, "#{count}")])
        m.user.send(msg)
      end

      private
      def games_json
        # Cache empty or time before last cache update > @cache_time
        if (!@cache || (Time.now.to_i - @cache_last_updated ) > @cache_time)
          bot.debug('Updating linux steam games cache')

          begin
            uri = @linuxgames_json_uri
            http = Net::HTTP.new(uri.host, uri.port)
            http.use_ssl = true
            response = http.get(uri.request_uri)
          rescue
            return nil
          end

          # Not a 200 response type
          if response.code_type != Net::HTTPOK
              return nil
          end

          # Check for .content_type == 'application/json'?
          @cache_last_updated = Time.now.to_i
          @cache = body = response.body
        else
          # Use cached body
          body = @cache
        end

        return JSON.parse(body)
      end

      def games_count
        json = games_json()

        if !json
          return nil
        end

        return json.select { |i, g| g == true || (g.is_a?(Hash) && g['Hidden'] != true) }.size
      end

    end
  end
end
