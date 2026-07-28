require "rails_helper"

RSpec.describe OptOutEvent, type: :model do
  it "requires a patient and opted_out_at" do
    event = OptOutEvent.new
    expect(event).not_to be_valid
    expect(event.errors[:patient]).to be_present
    expect(event.errors[:opted_out_at]).to be_present
  end
end
