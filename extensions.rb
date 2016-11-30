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
