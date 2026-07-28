require "rails_helper"

RSpec.describe CheckinTemplate, type: :model do
  it "requires a category included in the known list" do
    template = build(:checkin_template, category: "not_a_real_category")
    expect(template).not_to be_valid
    expect(template.errors[:category]).to be_present
  end

  describe "#condition_specific?" do
    it "is false when no conditions are linked" do
      template = create(:checkin_template)
      expect(template.condition_specific?).to be false
    end

    it "is true once a condition is linked" do
      template = create(:checkin_template)
      template.conditions << create(:condition)
      expect(template.condition_specific?).to be true
    end
  end

  describe "#seasonally_relevant?" do
    it "restricts hydration templates to summer months" do
      template = build(:checkin_template, category: "hydration")
      expect(template.seasonally_relevant?(date: Date.new(2026, 7, 1))).to be true
      expect(template.seasonally_relevant?(date: Date.new(2026, 12, 1))).to be false
    end

    it "has no seasonal restriction for other categories" do
      template = build(:checkin_template, category: "glucose")
      expect(template.seasonally_relevant?(date: Date.new(2026, 12, 1))).to be true
    end
  end
end
