class Patient < ApplicationRecord
  has_many :patient_conditions, dependent: :destroy
  has_many :conditions, through: :patient_conditions
  has_many :conversations, dependent: :destroy
  has_many :opt_out_events, dependent: :destroy

  validates :first_name, :last_name, :date_of_birth, :phone_number, presence: true

  AGE_BANDS = {
    "under_40" => 0...40,
    "40_to_59" => 40...60,
    "60_plus" => 60...Float::INFINITY
  }.freeze

  def opted_out?
    opt_out_events.exists?
  end

  def age
    return nil unless date_of_birth

    ((Date.current - date_of_birth) / 365.25).to_i
  end

  # Coarse segment used for engagement scoring/analytics rather than clinical precision.
  def age_band
    return "unknown" if age.nil?

    AGE_BANDS.find { |_band, range| range.cover?(age) }&.first || "unknown"
  end
end
