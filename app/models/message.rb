class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :message_variant, optional: true
  belongs_to :responds_to_message, class_name: "Message", optional: true
  has_one :response, class_name: "Message", foreign_key: "responds_to_message_id",
                      dependent: :nullify, inverse_of: :responds_to_message

  DIRECTIONS = %w[outbound inbound].freeze

  # Coarse, heuristic keyword scan — a real system would run this through an NLP
  # service, but the point is that clinical safety signals are detected independently
  # of, and regardless of, whatever the engagement-scoring model says about the reply.
  RED_FLAG_KEYWORDS = [
    "chest pain", "can't breathe", "cannot breathe", "unconscious", "suicidal",
    "severe bleeding", "passed out", "emergency", "can't wake", "cannot wake"
  ].freeze

  validates :direction, inclusion: { in: DIRECTIONS }
  validates :body, :sent_at, presence: true
  validate :variant_presence_matches_direction
  validate :responds_to_message_must_be_outbound_in_same_conversation

  before_validation :detect_red_flag_keywords

  scope :outbound, -> { where(direction: "outbound") }
  scope :inbound, -> { where(direction: "inbound") }

  def response_length
    body.to_s.length
  end

  def response_time_seconds
    return nil unless responds_to_message

    sent_at - responds_to_message.sent_at
  end

  private

  def variant_presence_matches_direction
    errors.add(:message_variant, "must be blank for inbound messages") if direction == "inbound" && message_variant.present?
  end

  def responds_to_message_must_be_outbound_in_same_conversation
    return if responds_to_message.blank?

    errors.add(:responds_to_message, "must be an outbound message") unless responds_to_message.direction == "outbound"
    errors.add(:responds_to_message, "must be in the same conversation") unless responds_to_message.conversation_id == conversation_id
    errors.add(:direction, "only inbound messages can respond to another message") unless direction == "inbound"
  end

  def detect_red_flag_keywords
    return unless direction == "inbound" && body.present?

    self.contains_red_flag = RED_FLAG_KEYWORDS.any? { |keyword| body.downcase.include?(keyword) }
  end
end
