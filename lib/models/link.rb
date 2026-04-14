# link.rb
#
# ActiveRecord model for Link

require 'open-uri'
require 'openssl'

class Link < ActiveRecord::Base
  validates :uri, presence: true
  validate :check_link_uniqueness

  before_create :set_live_show
  after_create  :fetch_page_title_async

  def set_live_show
    self.show ||= Shows.fetch_live_show_slug
  end

  def fetch_page_title_async
    Thread.new(self) do |link|
      begin
        content = URI.open(link.uri, ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE).read
        title = content.match(/<title>(.*?)<\/title>?/im)&.captures&.first
        link.update(title: title) if title
      rescue URI::InvalidURIError
        STDOUT.puts "Failed to fetch title for #{link.uri}."
      end
    end
  end

  def self.recent(days_ago = 1)
    where('created_at > ?', DateTime.now - days_ago).order(created_at: :desc)
  end

  def self.minutes_ago(minutes)
    where('created_at > ?', Time.now - (60 * minutes)).order(created_at: :desc) if minutes
  end

  private

  def check_link_uniqueness
    return unless uri
    Link.minutes_ago(30).each do |link|
      next if link.id == id
      if link.uri == uri
        errors.add(:uri, "Darn, #{link.user} beat you to #{link.uri}.")
        return
      end
    end
  end
end
