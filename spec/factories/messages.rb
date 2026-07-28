FactoryBot.define do
  factory :message do
    conversation
    direction { "outbound" }
    body { "Hi Pat, just checking in. How are you feeling today?" }
    sent_at { 1.day.ago }
    contains_red_flag { false }

    trait :inbound do
      direction { "inbound" }
      message_variant { nil }
      body { "Feeling okay, thanks!" }
    end
  end
end
