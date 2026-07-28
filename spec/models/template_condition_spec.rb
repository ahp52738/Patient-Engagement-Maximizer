require "rails_helper"

RSpec.describe TemplateCondition, type: :model do
  it "prevents linking the same condition to a template twice" do
    template = create(:checkin_template)
    condition = create(:condition)
    create(:template_condition, checkin_template: template, condition: condition)

    duplicate = build(:template_condition, checkin_template: template, condition: condition)
    expect(duplicate).not_to be_valid
  end
end
