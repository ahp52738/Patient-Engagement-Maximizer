FactoryBot.define do
  factory :conversation do
    patient
    started_at { 1.month.ago }
  end
end
