FactoryBot.define do
  factory :curation_review do
    message_variant
    reviewer_name { "clinical_review_bot" }
    action { "approved" }
    notes { nil }
    reviewed_at { 1.day.ago }
  end
end
