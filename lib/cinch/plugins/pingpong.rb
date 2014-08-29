# A Bit Of Fun.

module Cinch
  module Plugins
    class Suggestions
      include Cinch::Plugin

      match "ping",        :method => :command_ping        # !help suggest


      # Show help for the suggestions module
      def command_ping(m)
        m.user.send "PONG"
      end

      end

    end
  end
end
