class Condition < ApplicationRecord
  has_many :patient_conditions, dependent: :destroy
  has_many :patients, through: :patient_conditions
  has_many :template_conditions, dependent: :destroy
  has_many :checkin_templates, through: :template_conditions

  validates :name, presence: true, uniqueness: true

  def slug
    name.parameterize(separator: "_")
  end
end
