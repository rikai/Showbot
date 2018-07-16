require 'cinch/cooldown'

module Cinch
  module Plugins
    class Servers
      include Cinch::Plugin

      enforce_cooldown

      match /server$/i,       :method => :command_server          # !server
      match /server\s+(.+)/i, :method => :command_server_service  # !server <service>
      match /irc/i,           :method => :command_irc             # !irc
      match /mumble/i,        :method => :command_mumble          # !mumble
      match /peertube/i,      :method => :command_peertube        # !peertube

      def help
        [
          '!server - Meta-command for server info.',
          '!irc - IRC server info.',
          '!mumble - Mumble server info.'
        ].join "\n"
      end

      def help_irc
        [
          '!irc - IRC server info.',
          'Usage: !irc'
        ].join "\n"
      end

      def help_mumble
        [
          '!mumble - Mumble server info.',
          'Usage: !mumble'
        ].join "\n"
      end

      def command_server(m)
        m.user.send 'Usage: !server <service>'
        m.user.send 'where <service> is one of: irc, mumble'
      end

      def command_server_service(m, service)
        case service
        when 'irc'
          command_irc(m)
        when 'mumble'
          command_mumble(m)
        else
          m.user.send 'Sorry, that is not a service I know.'
        end
      end

      def command_irc(m)
        m.user.send 'IRC info - Server: irc.geekshed.net, Channel: #jupiterbroadcasting'
      end

      def command_mumble(m)
        m.user.send 'Mumble info - Server: mumble.jupiterbroadcasting.org, Port: 64734'
      end

      def command_peertube(m)
        m.user.send 'Official Peertube Server: https://getjupiter.com'
        m.user.send 'Community Peertube Server: https://peertube.linuxrocks.online'
      end
    end
  end
end

