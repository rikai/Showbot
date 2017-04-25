module Cinch
  module Plugins
    class Doobie
      include Cinch::Plugin

      match /doobie$/i,        :method => :command_doobie       # !doobie
      match /doobie\s+(\S+)/i, :method => :command_doobie_gift  # !doobie <user>

      def help
        '!doobie - Delicious Dank.'
      end

      def help_doobie
        [
          help,
          'Usage: !doobie [user]'
        ].join "\n"
      end

      def command_doobie(m)
        return if !m.channel?

        m.action_reply "gives #{m.user} a dankalicious hand-rolled doobie."
      end

      def command_doobie_gift(m, user_name)
        with_channel_user(m, user_name) do |to_user|
          m.action_reply "gives #{to_user} a dankalicious hand-rolled doobie as a gift from #{m.user}."
        end
      end

      private

      def with_channel_user(m, user)
        return unless m.channel?

        target_user = m.channel.users.keys.select do |channel_user|
          channel_user.to_s.casecmp(user).zero?
        end.first

        return if target_user.nil?

        yield target_user
      end
    end
  end
end
