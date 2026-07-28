FactoryBot.define do
  factory :patient_condition do
    patient
    condition
    diagnosed_at { 1.year.ago.to_date }
  end
end
