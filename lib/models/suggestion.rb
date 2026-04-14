# suggestion.rb
#
# Model that contains a title suggestion. These are created from the IRC chat
# bot via !suggest

class Suggestion < ActiveRecord::Base
  belongs_to :cluster, optional: true
  has_many   :votes

  validates :title, presence: true, length: { maximum: 40,
    too_long: I18n.t('messages.models.suggestion') }
  validate  :check_title_uniqueness, on: :create

  before_save   :fix_title
  before_create :check_cluster
  before_create :set_live_show

  # ------------------
  # Before Save
  # ------------------

  # Remove quotes from the title before saving
  def fix_title
    self.title = title.gsub(/^(?:'|")(.*)(?:'|")$/, '\1')
  end

  def check_cluster
    Suggestion.minutes_ago(30).each do |suggestion|
      next if suggestion.id == id
      if lev_sim(suggestion) > 0.7
        if suggestion.in_cluster?
          self.cluster = suggestion.cluster
        else
          cluster = Cluster.create
          suggestion.update!(cluster_id: cluster.id)
          self.cluster = cluster
        end
        return
      end
    end
  end

  def set_live_show
    self.show ||= Shows.fetch_live_show_slug
  end

  # ------------------
  # Class Methods
  # ------------------

  def self.recent(days_ago = 1)
    where('created_at > ?', DateTime.now - days_ago).order(created_at: :desc)
  end

  def self.minutes_ago(minutes)
    where('created_at > ?', Time.now - (60 * minutes)).order(created_at: :desc) if minutes
  end

  # Group suggestions by show slug.
  # Accepts an AR relation or array; defaults to all suggestions.
  # Returns an array of SuggestionSets.
  def self.group_by_show(collection = all)
    suggestion_sets = []
    last_show = nil
    last_time = nil
    split_interval = 0.75 # 18 hours

    collection.each do |suggestion|
      if suggestion_sets.empty? || last_show != suggestion.show || (last_time - suggestion.created_at) > split_interval
        suggestion_sets << SuggestionSet.new(suggestion.show)
      end

      last_show = suggestion.show
      last_time = suggestion.created_at

      suggestion_sets.last.add suggestion
    end

    suggestion_sets
  end

  # ------------------
  # Helper Methods
  # ------------------

  # Add a vote to the votes association for the user's IP.
  # Returns true if successful, false if the user has already voted.
  def vote_up(user_ip)
    return false if user_already_voted?(user_ip)
    votes.create(user_ip: user_ip) ? true : false
  end

  def user_already_voted?(user_ip)
    votes.where(user_ip: user_ip).exists?
  end

  def to_s
    "#{title} by #{user}"
  end

  def update_votes_counter_cache
    vote_count = votes.count
    if vote_count != votes_counter
      puts "Fixing mismatched count (#{vote_count}/#{votes_counter} for #{self})"
      update(votes_counter: votes.count)
    end
  end

  # Clustering

  def lev_sim(other_suggestion)
    distance = levenshtein(title.downcase, other_suggestion.title.downcase)
    1.0 - distance.to_f / [title.length, other_suggestion.title.length].max
  end

  def in_cluster?
    !!cluster_id
  end

  def top_of_cluster?
    in_cluster? ? id == cluster.top_suggestion.id : true
  end

  def total_for_cluster
    in_cluster? ? cluster.total_votes : votes.count
  end

  private

  def check_title_uniqueness
    return unless title
    Suggestion.minutes_ago(30).each do |suggestion|
      if suggestion.title.downcase == title.downcase
        errors.add(:title, "Darn, #{suggestion.user} beat you to \"#{suggestion.title}\".")
        return
      end
    end
  end
end


# Class to hold sets of suggestions for the group_by_show method of Suggestion
class SuggestionSet
  def initialize(slug = nil)
    @slug = slug
    @suggestions = []
    super()
  end

  def add(show)
    @suggestions << show
  end

  def to_s
    string = ""
    string << "Show #@slug\n"
    string << "  Titles:\n"
    string << @suggestions.map{|s| "  #{s.title}"}.join("\n")
    string
  end

  attr_accessor :slug, :suggestions
end

# https://github.com/threedaymonk/text/blob/master/lib/text/levenshtein.rb
def levenshtein(str1, str2)
  ar1 = str1.split(//)
  ar2 = str2.split(//)

  d = (0..ar2.length).to_a
  x = nil

  ar1.length.times do |i|
    e = i + 1
    ar2.length.times do |j|
      cost = (ar1[i] == ar2[j]) ? 0 : 1
      x = [d[j+1] + 1, e + 1, d[j] + cost].min
      d[j] = e
      e = x
    end
    d[ar2.length] = x
  end

  x
end
