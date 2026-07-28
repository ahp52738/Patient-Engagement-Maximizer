FactoryBot.define do
  factory :opt_out_event do
    patient
    opted_out_at { 1.day.ago }
    reason { "Replied STOP" }
  end
end
