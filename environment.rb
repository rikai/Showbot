require 'rubygems'
require 'bundler/setup'
require 'haml'
require 'i18n'
require 'dotenv'

require 'sinatra' unless defined?(Sinatra)
require 'sinatra/activerecord'

configure do
  Dotenv.load
  Dir[File.join(Dir.pwd, 'locales', '*.yml')].each {|file| I18n.load_path << file }
  I18n.config.enforce_available_locales = true
  I18n.config.default_locale = ENV['SHOWBOT_LOCALE']
  I18n.config.locale = I18n.config.default_locale

  # load models
  Dir.glob("#{File.dirname(__FILE__)}/lib/models/*.rb").sort.each { |lib| require lib }

  def t(key, **options)
    I18n.t(key, **options)
  end
end

configure(:production, :development) do
  current_directory = File.expand_path(File.dirname(__FILE__))
  sqlite_file = File.join(current_directory, 'db', "#{Sinatra::Base.environment}.db")

  set :database, ENV['SHOWBOT_DATABASE_URL'] || "sqlite3:#{sqlite_file}"

  ActiveRecord::Base.logger = Logger.new(STDOUT) if settings.development?
end

configure :test do
  puts 'Test configuration in use'
  set :database, { adapter: 'sqlite3', database: ':memory:' }
  ActiveRecord::MigrationContext.new(
    File.join(File.dirname(__FILE__), 'db', 'migrate'),
    ActiveRecord::Base.connection_pool.schema_migration
  ).migrate
end

LIVE_URL = ENV['DATA_JSON_URL']
