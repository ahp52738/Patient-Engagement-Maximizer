FactoryBot.define do
  factory :patient do
    sequence(:first_name) { |n| "Patient#{n}" }
    last_name { "Test" }
    date_of_birth { 50.years.ago.to_date }
    preferred_language { "en" }
    sequence(:phone_number) { |n| format("+1555000%04d", n) }
  end
end
