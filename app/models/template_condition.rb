class TemplateCondition < ApplicationRecord
  belongs_to :checkin_template
  belongs_to :condition

  validates :condition_id, uniqueness: { scope: :checkin_template_id }
end
