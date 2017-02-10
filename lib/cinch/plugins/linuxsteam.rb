require 'nokogiri'
require 'open-uri'

module Cinch
  module Plugins
    class Suggestions
      include Cinch::Plugin

      match "linuxgames",        :method => :command_ammount        # !help suggest


      # Show help for the suggestions module
      def command_ammount(m)
        # currently verry slow, May need to make a cron job that down loads the page daily
        doc = Nokogiri::HTML(open('http://store.steampowered.com/search/?os=linux&category1=998'))
        torm="showing 1 - 25 of "
        nonformated=doc.css(".search_pagination_left").first.text
        nonformated.slice! torm
        nonformated.slice! "	"
        formated=nonformated
        m.user.send "Linux Games On Steam"
      end

     

    end
  end
end
