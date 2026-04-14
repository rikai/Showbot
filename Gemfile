source 'https://rubygems.org'

ruby '~> 3.4'

# Regular
gem 'activesupport'
gem 'tzinfo'
gem 'tzinfo-data'
gem 'i18n'
gem 'rake', '~> 13.3.0'
gem 'dotenv'

group :backup do
  gem 'backup'
  gem 'fog'
  gem 'whenever', require: false
  gem 'net-ssh'
  gem 'excon'
  gem 'mail'
end

# Web
gem 'sinatra'
gem 'sinatra-reloader'
gem 'thin'
gem 'haml'
gem 'eat'

# Web-facing Showbot dependencies
gem 'stopwords', '~> 0.2'

# IRC bot dependencies (not needed for web-only)
group :irc do
  gem 'cinch'
  gem 'cinchize'
  gem 'chronic'
  gem 'chronic_duration'
  gem 'x'
  gem 'google-apis-calendar_v3'
  gem 'htmlentities'
  gem 'cinch-identify'
end

# Database
gem 'activerecord', '~> 7.1'
gem 'sinatra-activerecord'

# Development Gems
group :development, :test do
  gem 'rspec'
end

group :development do
  gem 'sqlite3'
  gem 'foreman'
  gem 'sass-embedded'
end

group :production do
  gem 'mysql2'
end

group :test do
  gem 'rack-test', require: false
  gem 'test-unit'
end


