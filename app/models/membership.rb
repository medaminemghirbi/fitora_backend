class Membership < ApplicationRecord
  belongs_to :client
  belongs_to :membership_plan
  belongs_to :company
  belongs_to :created_by, class_name: "User", optional: true

  has_many :bookings, dependent: :nullify
  has_many :payments, dependent: :nullify

  enum :status, { pending: 0, active: 1, expired: 2, cancelled: 3 }
  enum :payment_status, { unpaid: 0, partial: 1, paid: 2 }

  validates :starts_at, presence: true, if: :active?
  validates :discount, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_final_price

  scope :currently_active, -> { active.where("expires_at IS NULL OR expires_at >= ?", Time.current) }
  scope :expiring_soon, ->(within: 7.days) { currently_active.where(expires_at: Time.current..Time.current + within) }

  def usable_for?(location:, activity:)
    return false unless active? && (expires_at.nil? || expires_at >= Time.current)
    return false if membership_plan.booking_limit.present? && !membership_plan.unlimited_bookings? && remaining_bookings.to_i <= 0

    membership_plan.grants_access_to?(location: location, activity: activity)
  end

  def consume_booking!
    return if membership_plan.unlimited_bookings?
    return if remaining_bookings.nil?

    decrement!(:remaining_bookings)
  end

  def restore_booking!
    return if membership_plan.unlimited_bookings?
    return if remaining_bookings.nil?

    increment!(:remaining_bookings)
  end

  private

  def compute_final_price
    return if membership_plan.blank?

    self.final_price = [ membership_plan.price - discount.to_f, 0 ].max
  end
end
