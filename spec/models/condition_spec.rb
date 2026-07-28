require "rails_helper"

RSpec.describe Condition, type: :model do
  it "requires a unique name" do
    create(:condition, name: "Type 2 Diabetes")
    duplicate = build(:condition, name: "Type 2 Diabetes")
    expect(duplicate).not_to be_valid
  end

  describe "#slug" do
    it "parameterizes the name" do
      condition = build(:condition, name: "Type 2 Diabetes")
      expect(condition.slug).to eq("type_2_diabetes")
    end
  end
end
