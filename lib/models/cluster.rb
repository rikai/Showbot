# cluster.rb
#
# Model that contains a set of similar title suggestions, determined by
# string metrics.

class Cluster < ActiveRecord::Base
  has_many :suggestions, -> { order(votes_counter: :desc, created_at: :desc) }
  has_one :top_suggestion, -> { order(votes_counter: :desc, created_at: :asc) }, class_name: 'Suggestion'

  def total_votes
    suggestions.sum(:votes_counter)
  end

  def self.recent(days_ago = 1)
    from = DateTime.now - days_ago
    joins(:suggestions).where('suggestions.created_at > ?', from).order('suggestions.created_at DESC')
  end
end
