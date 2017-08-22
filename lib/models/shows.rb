# Class to hold all of the shows and some sweet helper methods

require 'json'

require './lib/models/show.rb'

class Shows
  def initialize(show_hashes)
    @shows = []
    if show_hashes.length > 0
      self.load(show_hashes)
    end
  end
  
  # Adds the provided shows to the shows array.
  def load(show_hashes)
    show_hashes.each do |show_hash|
      @shows.push Show.new(show_hash)
    end
  end
  
  def get_shows
    @shows
  end

  # Returns the first show that matches the given keyword; 
  # otherwise, returns nil.
  def find_show(keyword)
    if !keyword
      return nil
    end
    
    @shows.each do |show|
      if show.matches? keyword
        return show
      end
    end
    
    return nil
  end

  # Returns the title of the show that matches keyword; otherwise, returns nil.
  # TODO(thefirstofthe300): Rename this. get_show_title is probably better.
  #                         Also, it's probably more semantic to return nil
  def find_show_title(keyword)
    show = find_show(keyword)
    
    if show
      return show.title
    end
    
    return keyword
  end

  # Returns the live show slug.
  # TODO: Figure out how to deal with this properly if it is nil instead of erroring out.
  # TODO(thefirstofthe300): Write tests for these two functions. Probably will
  # require mocking?
  def fetch_live_show_slug
    slug = nil

    begin
      live_hash = JSON.parse(open(LIVE_URL).read)
      if live_hash and live_hash.has_key?("live") and live_hash["live"]
        # Show is live, read show name
        broadcast = live_hash["broadcast"] if live_hash.has_key? "broadcast"
        slug = broadcast["slug"] if broadcast.has_key? "slug"
      end
    rescue OpenURI::HTTPError
      puts "Error: #{LIVE_URL} looks to be down."
    end

    return slug
  end

  # Returns the show object for the live show
  def fetch_live_show
    find_show(fetch_live_show_slug)
  end

end
