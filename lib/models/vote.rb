# vote.rb
#
# Model that contains a single vote for a user attached to a suggestion.

class Vote < ActiveRecord::Base
  belongs_to :suggestion, counter_cache: :votes_counter

  validates :user_ip, presence: true
end
