require "rails_helper"

RSpec.describe PatientCondition, type: :model do
  it "prevents linking the same condition to a patient twice" do
    patient = create(:patient)
    condition = create(:condition)
    create(:patient_condition, patient: patient, condition: condition)

    duplicate = build(:patient_condition, patient: patient, condition: condition)
    expect(duplicate).not_to be_valid
  end
end
