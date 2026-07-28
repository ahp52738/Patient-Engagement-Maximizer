class VariantEngagementStat < ApplicationRecord
  belongs_to :message_variant

  # "global" ignores patient segment entirely — the last-resort fallback for
  # brand new variants with no send history at all.
  GLOBAL_SEGMENT = "global"

  validates :segment_key, presence: true, uniqueness: { scope: :message_variant_id }
  validates :sends_count, :responses_count, :red_flag_count, numericality: { greater_than_or_equal_to: 0 }
end
