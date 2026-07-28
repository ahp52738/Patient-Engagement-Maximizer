class CurationReview < ApplicationRecord
  belongs_to :message_variant

  ACTIONS = %w[approved edited rejected].freeze

  validates :reviewer_name, presence: true
  validates :action, inclusion: { in: ACTIONS }
  validates :reviewed_at, presence: true
end
