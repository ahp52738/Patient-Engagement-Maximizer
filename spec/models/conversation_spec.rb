require "rails_helper"

RSpec.describe Conversation, type: :model do
  it "requires a patient and a started_at" do
    conversation = Conversation.new
    expect(conversation).not_to be_valid
    expect(conversation.errors[:patient]).to be_present
    expect(conversation.errors[:started_at]).to be_present
  end
end
