FactoryBot.define do
  factory :checkin_template do
    sequence(:name) { |n| "Template #{n}" }
    category { "glucose" }
    description { "A check-in template used for testing." }
  end
end
