# ActiveRecord model for API keys for Showbot

require 'securerandom'

class ApiKey < ActiveRecord::Base
  before_create do
    # Must truncate since urlsafe_base64 doesn't generate the exact length
    self.value = SecureRandom.urlsafe_base64(16)[0...16]
  end
end
