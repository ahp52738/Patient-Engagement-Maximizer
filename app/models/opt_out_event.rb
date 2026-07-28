class OptOutEvent < ApplicationRecord
  belongs_to :patient

  validates :opted_out_at, presence: true
end
