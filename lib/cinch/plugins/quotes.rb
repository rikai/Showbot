require 'cinch/cooldown'

module Cinch
  module Plugins
    class Quotes
      include Auth::AdminPlugin

      enforce_cooldown

      match /quote\s+(.+)/i, :method => :command_quote
      match /([^\s]+)/i,     :method => :command_quote
      [{
        # This pattern matches /quote add <nick> <quote with spaces>
        :pattern => /quote\s+add\s+([a-z][a-z0-9\-\[\]\\`\^\{\}]+)\s+(.+)/i,
        :method => :command_quote_add,
        :unauthorized_msg => "You are not authorized to add a quote."
      },
      {
        # Matches /quote del <nick> <quote with spaces>
        :pattern => /quote\s+del\s+([a-z][a-z0-9\-\[\]\\`\^\{\}]+)\s+(.+)/i,
        :method => :command_quote_del,
        :unauthorized_msg => "You are not authorized to delete a quote."
      },
      {
        # Matches /quote alias add <original> <alias>
        :pattern => /quote\s+alias\s+add\s+([a-z][a-z0-9\-\[\]\\`\^\{\}]+)\s+([a-z][a-z0-9\-\[\]\\`\^\{\}]+)/i,
        :method => :command_alias_add,
        :unauthorized_msg => "You are not authorized to add an alias."
      },
      {
        # Matches /quote alias del <original> <alias>
        :pattern => /quote\s+alias\s+del\s+([a-z][a-z0-9\-\[\]\\`\^\{\}]+)\s+([a-z][a-z0-9\-\[\]\\`\^\{\}]+)/i,
        :method => :command_alias_del,
        :unauthorized_msg => "You are not authorized to delete an alias."
      }].each do |m|
        admin_match m[:pattern], {
          :method => m[:method],
          :unauthorized_msg => m[:unauthorized_msg]
        }
      end

      def initialize(*args)
        super
        if !config[:quotes_file].nil?
          puts File.dirname(__FILE__)
          @can_save = true
          begin
            @quotes_path = File.join(File.dirname(__FILE__), "../../#{config[:quotes_file]}")
            quotes = YAML.load_file(@quotes_path)
            @quote_list = QuoteList.new(quotes)
          rescue Errno::ENOENT
            @quote_list = QuoteList.new(nil)
          end
        else
          @can_save = false
          @quote_list = QuoteList.new(nil)
        end
      end

      def command_quote(m, name)
        m.reply @quote_list.quote_for name
      end

      private

      def command_quote_add(m, name, quote)
        @quote_list.add(name, quote)
        m.reply("Quote added!")
      end

      def command_quote_del(m, name, quote)
        @quote_list.del(name, quote)
        m.reply("Quote removed!")
      end

      def command_alias_add(m, original, alias_name)
        @quote_list.add_alias(original, alias_name)
        m.reply("Alias added!")
      end

      def command_alias_del(m, original, alias_name)
        @quote_list.del_alias(original, alias_name)
        m.reply("Alias removed!")
      end
      
      private
      
      def save_to_disk
        if @can_save
          File.open(@quotes_path, "w") {|file| file.write(@quote_list.get_yaml)}
        end
      end
    end
  end
end

