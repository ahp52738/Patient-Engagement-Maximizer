FactoryBot.define do
  factory :message_variant do
    checkin_template
    body { "Hi {first_name}, just checking in. How are you feeling today?" }
    status { "draft" }
    created_by { "content_team" }

    trait :active do
      status { "active" }
    end
  end
end
