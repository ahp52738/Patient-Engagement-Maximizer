FactoryBot.define do
  factory :variant_engagement_stat do
    message_variant
    segment_key { "global" }
    sends_count { 10 }
    responses_count { 5 }
    response_rate { 0.5 }
    avg_response_length { 20.0 }
    red_flag_count { 0 }
    calculated_at { Time.current }
  end
end
