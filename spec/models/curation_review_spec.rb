require "rails_helper"

RSpec.describe CurationReview, type: :model do
  it "requires a known action" do
    review = build(:curation_review, action: "not_a_real_action")
    expect(review).not_to be_valid
    expect(review.errors[:action]).to be_present
  end
end
