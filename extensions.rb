require 'cinchize'

SILENT_MODE="SILENT_MODE"

class Cinch::User
  def send(text)
    if ENV[SILENT_MODE].downcase == 'true'
      puts "%s: Private message to %s = %s" % [SILENT_MODE, nick, text]
    else
      super text
    end
  end
end

class Cinch::Message
  def reply(text)
    if ENV[SILENT_MODE].downcase == 'true'
      puts "%s: Reply to %s = %s" % [SILENT_MODE, user.nick, text]
    else
      text = text.to_s
      if @channel && prefix
        text = text.split("\n").map {|l| "#{user.nick}: #{l}"}.join("\n")
      end
      reply_target.send(text)
    end
  end
end

class Cinch::Message
  def action_reply(text)
    if ENV[SILENT_MODE].downcase == 'true'
      puts "%s: Action reply to %s = %s" % [SILENT_MODE, user.nick, text]
    else
      text = text.to_s
      reply_target.action(text)
    end
  end
end

