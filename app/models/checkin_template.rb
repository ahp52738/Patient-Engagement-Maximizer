class CheckinTemplate < ApplicationRecord
  has_many :template_conditions, dependent: :destroy
  has_many :conditions, through: :template_conditions
  has_many :message_variants, dependent: :destroy

  CATEGORIES = %w[glucose symptoms medication hydration].freeze

  # Categories relevant only during part of the year. Kept as a simple hash rather than
  # a schema column since it's a small, fixed business rule, not curated data.
  SEASONAL_MONTHS = {
    "hydration" => (5..9)
  }.freeze

  validates :name, presence: true, uniqueness: true
  validates :category, presence: true, inclusion: { in: CATEGORIES }

  # Templates with no linked conditions (e.g. Summer Hydration) are considered
  # broadly relevant and are offered to every patient regardless of diagnosis.
  def condition_specific?
    conditions.any?
  end

  def seasonally_relevant?(date: Date.current)
    months = SEASONAL_MONTHS[category]
    months.nil? || months.cover?(date.month)
  end
end
