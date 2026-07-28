class Conversation < ApplicationRecord
  belongs_to :patient
  has_many :messages, dependent: :destroy

  validates :started_at, presence: true
end
