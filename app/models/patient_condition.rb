class PatientCondition < ApplicationRecord
  belongs_to :patient
  belongs_to :condition

  validates :condition_id, uniqueness: { scope: :patient_id }
end
