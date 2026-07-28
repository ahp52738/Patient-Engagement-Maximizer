require "rails_helper"

RSpec.describe Recommendations::Engine do
  let(:condition) { create(:condition, name: "Type 2 Diabetes") }
  let(:template) do
    create(:checkin_template, category: "glucose").tap { |t| t.conditions << condition }
  end
  let(:patient) { create(:patient, date_of_birth: 70.years.ago.to_date) } # 60_plus

  before { patient.conditions << condition }

  it "returns no recommendations for an opted-out patient" do
    create(:opt_out_event, patient: patient)
    create(:message_variant, :active, checkin_template: template)

    expect(described_class.new(patient).call).to eq([])
  end

  it "excludes condition-specific templates the patient doesn't have" do
    other_condition = create(:condition, name: "Hypertension")
    other_template = create(:checkin_template, category: "medication").tap { |t| t.conditions << other_condition }
    create(:message_variant, :active, checkin_template: other_template)

    expect(described_class.new(patient).call).to eq([])
  end

  it "includes general templates regardless of the patient's conditions" do
    general_template = create(:checkin_template, category: "hydration")
    variant = create(:message_variant, :active, checkin_template: general_template)

    recommendations = described_class.new(patient, as_of: Date.new(2026, 7, 15)).call

    expect(recommendations.map(&:message_variant)).to include(variant)
  end

  it "excludes seasonal templates outside their active months" do
    general_template = create(:checkin_template, category: "hydration")
    create(:message_variant, :active, checkin_template: general_template)

    recommendations = described_class.new(patient, as_of: Date.new(2026, 12, 15)).call

    expect(recommendations).to eq([])
  end

  it "excludes a variant sent to the patient within the cooldown window" do
    variant = create(:message_variant, :active, checkin_template: template)
    conversation = create(:conversation, patient: patient)
    create(:message, conversation: conversation, message_variant: variant, sent_at: 1.day.ago)

    recommendations = described_class.new(patient).call

    expect(recommendations.map(&:message_variant)).not_to include(variant)
  end

  it "prefers the most specific segment stat available" do
    variant = create(:message_variant, :active, checkin_template: template)
    create(:variant_engagement_stat, message_variant: variant, segment_key: "global",
      sends_count: 100, responses_count: 40, response_rate: 0.4)
    create(:variant_engagement_stat, message_variant: variant, segment_key: "condition:type_2_diabetes",
      sends_count: 100, responses_count: 60, response_rate: 0.6)
    create(:variant_engagement_stat, message_variant: variant, segment_key: "condition:type_2_diabetes|age_band:60_plus",
      sends_count: 100, responses_count: 80, response_rate: 0.8)

    recommendation = described_class.new(patient).call.first

    expect(recommendation.rationale).to include("similar condition and age")
    expect(recommendation.score).to eq(0.8) # sample size above the confidence threshold, no exploration bonus
  end

  it "adds an exploration bonus for lightly-tested variants" do
    variant = create(:message_variant, :active, checkin_template: template)
    create(:variant_engagement_stat, message_variant: variant, segment_key: "global",
      sends_count: 5, responses_count: 3, response_rate: 0.6)

    recommendation = described_class.new(patient).call.first

    expect(recommendation.score).to eq(0.65)
    expect(recommendation.rationale).to include("prioritized to gather more data")
  end

  it "falls back to a cold-start estimate for variants with no history at all" do
    variant = create(:message_variant, :active, checkin_template: template)

    recommendation = described_class.new(patient).call.first

    expect(recommendation.message_variant).to eq(variant)
    expect(recommendation.score).to eq(0.35)
    expect(recommendation.rationale).to include("No send history yet")
  end

  it "ranks variants by score and respects the limit" do
    high = create(:message_variant, :active, checkin_template: template, body: "Hi {first_name}, variant high")
    low = create(:message_variant, :active, checkin_template: template, body: "Hi {first_name}, variant low")
    create(:variant_engagement_stat, message_variant: high, segment_key: "global",
      sends_count: 50, responses_count: 45, response_rate: 0.9)
    create(:variant_engagement_stat, message_variant: low, segment_key: "global",
      sends_count: 50, responses_count: 5, response_rate: 0.1)

    recommendations = described_class.new(patient, limit: 1).call

    expect(recommendations.length).to eq(1)
    expect(recommendations.first.message_variant).to eq(high)
  end

  it "never recommends a variant that hasn't cleared curation" do
    create(:message_variant, checkin_template: template, status: "pending_review")

    expect(described_class.new(patient).call).to eq([])
  end
end
