require "rails_helper"

RSpec.describe Patient, type: :model do
  it "is invalid without required demographics" do
    patient = Patient.new
    expect(patient).not_to be_valid
    expect(patient.errors[:first_name]).to be_present
    expect(patient.errors[:last_name]).to be_present
    expect(patient.errors[:date_of_birth]).to be_present
    expect(patient.errors[:phone_number]).to be_present
  end

  describe "#age_band" do
    it "buckets younger patients as under_40" do
      patient = build(:patient, date_of_birth: 25.years.ago.to_date)
      expect(patient.age_band).to eq("under_40")
    end

    it "buckets middle-aged patients as 40_to_59" do
      patient = build(:patient, date_of_birth: 45.years.ago.to_date)
      expect(patient.age_band).to eq("40_to_59")
    end

    it "buckets older patients as 60_plus" do
      patient = build(:patient, date_of_birth: 70.years.ago.to_date)
      expect(patient.age_band).to eq("60_plus")
    end
  end

  describe "#opted_out?" do
    it "is false with no opt-out events" do
      expect(build(:patient).opted_out?).to be false
    end

    it "is true once an opt-out event exists" do
      patient = create(:patient)
      create(:opt_out_event, patient: patient)
      expect(patient.opted_out?).to be true
    end
  end
end
