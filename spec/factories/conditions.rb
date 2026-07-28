FactoryBot.define do
  factory :condition do
    sequence(:name) { |n| "Condition #{n}" }
  end
end
