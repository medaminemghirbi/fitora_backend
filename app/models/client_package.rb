class ClientPackage < ApplicationRecord
  belongs_to :client
  belongs_to :package
  has_many :bookings, dependent: :nullify
  has_many :payments, dependent: :nullify

  enum :status, { pending: 0, active: 1, expired: 2, cancelled: 3 }

  scope :currently_active, -> { active.where("expires_at IS NULL OR expires_at >= ?", Time.current) }

  def usable_for?(activity:)
    return false unless active? && (expires_at.nil? || expires_at >= Time.current)
    return false if remaining_credits <= 0

    package.activity_id.nil? || package.activity_id == activity.id
  end

  def consume_credit!
    decrement!(:remaining_credits)
  end

  def restore_credit!
    increment!(:remaining_credits)
  end
end
