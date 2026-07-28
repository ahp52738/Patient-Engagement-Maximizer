require "rails_helper"

RSpec.describe Message, type: :model do
  it "rejects an inbound message that has a message_variant attached" do
    conversation = create(:conversation)
    variant = create(:message_variant, :active)
    message = build(:message, :inbound, conversation: conversation, message_variant: variant)

    expect(message).not_to be_valid
    expect(message.errors[:message_variant]).to be_present
  end

  it "requires a responds_to_message to be outbound" do
    conversation = create(:conversation)
    inbound = create(:message, :inbound, conversation: conversation)
    reply = build(:message, :inbound, conversation: conversation, responds_to_message: inbound)

    expect(reply).not_to be_valid
    expect(reply.errors[:responds_to_message]).to be_present
  end

  it "requires a responds_to_message to be in the same conversation" do
    variant = create(:message_variant, :active)
    outbound = create(:message, conversation: create(:conversation), message_variant: variant)
    other_conversation = create(:conversation)
    reply = build(:message, :inbound, conversation: other_conversation, responds_to_message: outbound)

    expect(reply).not_to be_valid
    expect(reply.errors[:responds_to_message]).to be_present
  end

  describe "red flag detection" do
    it "flags an inbound message that mentions a safety keyword" do
      message = create(:message, :inbound, body: "I've had chest pain since this morning")
      expect(message.contains_red_flag).to be true
    end

    it "does not flag routine inbound replies" do
      message = create(:message, :inbound, body: "Feeling fine today, thanks!")
      expect(message.contains_red_flag).to be false
    end

    it "does not evaluate outbound check-in messages" do
      variant = create(:message_variant, :active, body: "Hi {first_name}, any chest pain today?")
      message = create(:message, message_variant: variant, body: "Hi Pat, any chest pain today?")
      expect(message.contains_red_flag).to be false
    end
  end

  describe "#response_time_seconds" do
    it "is the gap between the check-in and the reply" do
      conversation = create(:conversation)
      variant = create(:message_variant, :active)
      outbound = create(:message, conversation: conversation, message_variant: variant, sent_at: 2.hours.ago)
      inbound = create(:message, :inbound, conversation: conversation, sent_at: 1.hour.ago, responds_to_message: outbound)

      expect(inbound.response_time_seconds).to be_within(1).of(1.hour.to_i)
    end

    it "is nil when the message is not a response" do
      message = create(:message, :inbound)
      expect(message.response_time_seconds).to be_nil
    end
  end
end
