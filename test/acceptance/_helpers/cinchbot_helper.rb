require_relative 'globals_helper'

def start_cinchbot
  Process.fork do
    require 'optparse'
    require 'cinchize'

# Require all of the models files
    Dir.glob("#{APP_ROOT}/lib/models/*.rb").sort.each { |lib| require lib }

    options = {
      :ontop => true,
      :system => false,
      :local_config => File.join(TEST_ROOT, '_config/cinchize.yml'),
      :system_config => File.join(TEST_ROOT, '_config/cinchize.global.yml'),
      :action => :start
    }

    daemon = Cinchize::Cinchize.new *Cinchize.config(options, 'network_test')
    daemon.send options[:action]
  end
end

def kill_cinchbot cinchbot
  Process.kill :TERM, cinchbot
  Process.wait cinchbot
end
