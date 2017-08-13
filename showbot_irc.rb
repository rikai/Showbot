require File.join(File.dirname(__FILE__), 'environment')

require 'optparse'
require 'cinchize'
require 'droplet_kit'
require 'auth/admin_plugin'

# Required to parse the cinchize.yml file properly
if RUBY_VERSION < '1.9.3'
  YAML::ENGINE.yamler = 'psych'
end

Options = {
  :ontop => true,
  :system => false,
  :local_config => File.join(Dir.pwd, 'cinchize.yml'),
  :system_config => '/etc/cinchize.yml',
  :action => :start,
}

options = Options.dup

SHOWS_JSON = File.expand_path(File.join(File.dirname(__FILE__), "public", "shows.json")) unless defined? SHOWS_JSON

Auth::AdminPlugin.init(YAML.load_file(Options[:local_config])['auth_admin']['admins'])

daemon = Cinchize::Cinchize.new *Cinchize.config(options, ARGV.first)
daemon.send options[:action]
