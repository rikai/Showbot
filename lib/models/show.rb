# The Show class holds data for a specific show. In addition to being a data
# container, it also provides for matching a search term. The following
# (read-only) attributes are available:
#
#   title:   (string) The show's title
#   url:     (string) The URL slug of the show
#   rss:     (string) The RSS feed URL of the show
#   aliases: (array[string]) An array of aliases that can additionally match
#     the show
class Show
  attr_reader :title, :url, :rss, :aliases, :limit

  # param json_hash: (hash) A hash of show data with the following keys:
  #   title: (string) The show's title
  #   url: (string) The URL slug of the show
  #   rss: (string) The RSS feed URL of the show
  #   aliases: (array[string]) [Optional] An array of aliases
  # NOTE: json_hash is just a hash, and doesn't need anything to do with JSON
  #
  # The aliases will all be downcased before being stored internally
  def initialize(json_hash)
    @title = json_hash["title"]
    @url = json_hash["url"]
    @rss = json_hash["rss"]
    @limit = json_hash.key?("limit") ? json_hash["limit"] : 40
    @aliases = (json_hash["aliases"] || []).map do |show_alias|
      show_alias.downcase
    end
  end

  # Tests if a search term matches this show, against a variety of checks.
  # param search_term: (string) The term to search against
  # returns: (boolean) True if matched, false otherwise
  # The search term is compared case-insensitively against the various fields.
  # It is tested against aliases, the URL slug, and then the show title.
  def matches?(search_term)
    search_term = search_term.downcase

    matches_alias?(search_term) || matches_url?(search_term) || matches_title?(search_term)
  end

  private

  # Tests if search_term exactly matches the URL slug
  def matches_url?(search_term)
    url.downcase == search_term
  end

  # Tests if the search term is contained in the show title
  def matches_title?(search_term)
    title.downcase.include? search_term
  end

  # Tests if the search term exactly matches one of the aliases
  def matches_alias?(search_term)
    aliases.include? search_term
  end
end
