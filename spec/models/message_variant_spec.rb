require "rails_helper"

RSpec.describe MessageVariant, type: :model do
  it "requires the {first_name} personalization token in the body" do
    variant = build(:message_variant, body: "Hi there, how are you?")
    expect(variant).not_to be_valid
    expect(variant.errors[:body]).to be_present
  end

  describe "#render_for" do
    it "substitutes the patient's first name" do
      variant = build(:message_variant, body: "Hi {first_name}, how are you?")
      patient = build(:patient, first_name: "Alex")
      expect(variant.render_for(patient)).to eq("Hi Alex, how are you?")
    end
  end

  describe "curation workflow" do
    it "moves from draft through to active only via valid transitions" do
      variant = create(:message_variant, status: "draft")

      expect { variant.activate! }.to raise_error(MessageVariant::InvalidTransition)

      variant.submit_for_review!
      expect(variant.reload.status).to eq("pending_review")

      variant.approve!(reviewer: "clinical_review_bot")
      expect(variant.reload.status).to eq("approved")
      expect(variant.curation_reviews.last.action).to eq("approved")

      variant.activate!
      expect(variant.reload.status).to eq("active")
    end

    it "returns a rejected variant to draft and logs the review" do
      variant = create(:message_variant, status: "pending_review")

      variant.reject!(reviewer: "clinical_review_bot", notes: "Reading level too high")

      expect(variant.reload.status).to eq("draft")
      review = variant.curation_reviews.last
      expect(review.action).to eq("rejected")
      expect(review.notes).to eq("Reading level too high")
    end

    it "logs an edit without changing status" do
      variant = create(:message_variant, status: "pending_review", body: "Hi {first_name}, old wording?")

      variant.edit!(reviewer: "content_team", new_body: "Hi {first_name}, new wording?")

      expect(variant.reload.body).to eq("Hi {first_name}, new wording?")
      expect(variant.status).to eq("pending_review")
      expect(variant.curation_reviews.last.action).to eq("edited")
    end

    it "will not activate a variant that was never approved" do
      variant = create(:message_variant, status: "draft")
      expect { variant.activate! }.to raise_error(MessageVariant::InvalidTransition)
    end

    it "will not archive a draft variant" do
      variant = create(:message_variant, status: "draft")
      expect { variant.archive! }.to raise_error(MessageVariant::InvalidTransition)
    end
  end

  describe ".recommendable" do
    it "only includes active variants" do
      active = create(:message_variant, :active)
      create(:message_variant, status: "approved")
      create(:message_variant, status: "draft")

      expect(MessageVariant.recommendable).to contain_exactly(active)
    end
  end
end
