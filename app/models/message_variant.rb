class MessageVariant < ApplicationRecord
  class InvalidTransition < StandardError; end

  belongs_to :checkin_template
  has_many :messages, dependent: :restrict_with_error
  has_many :curation_reviews, dependent: :destroy
  has_many :variant_engagement_stats, dependent: :destroy

  STATUSES = %w[draft pending_review approved active archived].freeze

  validates :body, :created_by, presence: true
  validates :status, inclusion: { in: STATUSES }
  validate :body_includes_personalization_token

  scope :active, -> { where(status: "active") }

  # Only variants a human has explicitly approved and activated are eligible
  # to be sent or recommended — the model/analytics never bypass curation.
  scope :recommendable, -> { where(status: "active") }

  def render_for(patient)
    body.gsub("{first_name}", patient.first_name)
  end

  def submit_for_review!
    raise InvalidTransition, "must be draft to submit for review" unless status == "draft"

    update!(status: "pending_review")
  end

  def approve!(reviewer:, notes: nil)
    raise InvalidTransition, "must be pending_review to approve" unless status == "pending_review"

    transaction do
      update!(status: "approved")
      curation_reviews.create!(reviewer_name: reviewer, action: "approved", notes: notes, reviewed_at: Time.current)
    end
  end

  def reject!(reviewer:, notes: nil)
    raise InvalidTransition, "must be pending_review to reject" unless status == "pending_review"

    transaction do
      update!(status: "draft")
      curation_reviews.create!(reviewer_name: reviewer, action: "rejected", notes: notes, reviewed_at: Time.current)
    end
  end

  def edit!(reviewer:, new_body:, notes: nil)
    transaction do
      update!(body: new_body)
      curation_reviews.create!(reviewer_name: reviewer, action: "edited", notes: notes, reviewed_at: Time.current)
    end
  end

  def activate!
    raise InvalidTransition, "must be approved to activate" unless status == "approved"

    update!(status: "active")
  end

  def archive!
    raise InvalidTransition, "must be approved or active to archive" unless %w[approved active].include?(status)

    update!(status: "archived")
  end

  private

  def body_includes_personalization_token
    errors.add(:body, "must include the {first_name} placeholder") if body.present? && !body.include?("{first_name}")
  end
end
