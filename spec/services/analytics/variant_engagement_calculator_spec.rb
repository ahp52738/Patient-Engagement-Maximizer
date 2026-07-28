require "rails_helper"

RSpec.describe Analytics::VariantEngagementCalculator do
  it "computes response rate and average response length across segment tiers" do
    condition = create(:condition, name: "Type 2 Diabetes")
    template = create(:checkin_template, category: "glucose")
    template.conditions << condition
    variant = create(:message_variant, :active, checkin_template: template)

    patient = create(:patient, date_of_birth: 70.years.ago.to_date) # 60_plus
    patient.conditions << condition
    conversation = create(:conversation, patient: patient)

    responded_send = create(:message, conversation: conversation, message_variant: variant, sent_at: 2.days.ago)
    create(:message, :inbound, conversation: conversation, body: "Doing okay, thanks",
      sent_at: 2.days.ago + 10.minutes, responds_to_message: responded_send)
    create(:message, conversation: conversation, message_variant: variant, sent_at: 1.day.ago) # no reply

    described_class.call

    global_stat = variant.variant_engagement_stats.find_by(segment_key: "global")
    expect(global_stat.sends_count).to eq(2)
    expect(global_stat.responses_count).to eq(1)
    expect(global_stat.response_rate).to eq(0.5)
    expect(global_stat.avg_response_length).to eq("Doing okay, thanks".length)

    condition_stat = variant.variant_engagement_stats.find_by(segment_key: "condition:type_2_diabetes")
    expect(condition_stat.sends_count).to eq(2)
    expect(condition_stat.responses_count).to eq(1)

    segment_stat = variant.variant_engagement_stats.find_by(segment_key: "condition:type_2_diabetes|age_band:60_plus")
    expect(segment_stat.sends_count).to eq(2)
    expect(segment_stat.responses_count).to eq(1)
  end

  it "does not attribute sends to conditions the template isn't linked to" do
    unrelated_condition = create(:condition, name: "Hypertension")
    template = create(:checkin_template, category: "medication") # no linked conditions
    variant = create(:message_variant, :active, checkin_template: template)
    patient = create(:patient)
    patient.conditions << unrelated_condition
    conversation = create(:conversation, patient: patient)
    create(:message, conversation: conversation, message_variant: variant, sent_at: 1.day.ago)

    described_class.call

    expect(variant.variant_engagement_stats.find_by(segment_key: "global").sends_count).to eq(1)
    expect(variant.variant_engagement_stats.where("segment_key LIKE 'condition:%'")).to be_empty
  end

  it "counts red-flagged responses" do
    condition = create(:condition)
    template = create(:checkin_template)
    template.conditions << condition
    variant = create(:message_variant, :active, checkin_template: template)
    patient = create(:patient)
    patient.conditions << condition
    conversation = create(:conversation, patient: patient)

    send_message = create(:message, conversation: conversation, message_variant: variant, sent_at: 1.day.ago)
    create(:message, :inbound, conversation: conversation, body: "I've had chest pain since this morning",
      sent_at: 1.day.ago + 5.minutes, responds_to_message: send_message)

    described_class.call

    expect(variant.variant_engagement_stats.find_by(segment_key: "global").red_flag_count).to eq(1)
  end

  it "is idempotent — running it twice does not duplicate stat rows" do
    template = create(:checkin_template)
    variant = create(:message_variant, :active, checkin_template: template)
    patient = create(:patient)
    conversation = create(:conversation, patient: patient)
    create(:message, conversation: conversation, message_variant: variant, sent_at: 1.day.ago)

    described_class.call
    described_class.call

    expect(variant.variant_engagement_stats.where(segment_key: "global").count).to eq(1)
  end
end
