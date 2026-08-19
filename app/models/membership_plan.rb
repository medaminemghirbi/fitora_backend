class MembershipPlan < ApplicationRecord
  belongs_to :company

  has_many :membership_plan_locations, dependent: :destroy
  has_many :locations, through: :membership_plan_locations
  has_many :membership_plan_activities, dependent: :destroy
  has_many :activities, through: :membership_plan_activities
  has_many :memberships, dependent: :restrict_with_error

  # Replaces the old free-form duration_days column — an "abonnement" now
  # only ever runs monthly/quarterly/semi_annual/yearly, per product
  # decision. #duration_days below derives the actual day count from this.
  enum :billing_period, { monthly: 0, quarterly: 1, semi_annual: 2, yearly: 3 }

  DURATION_DAYS_BY_PERIOD = { "monthly" => 30, "quarterly" => 90, "semi_annual" => 180, "yearly" => 365 }.freeze

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :booking_limit, numericality: { greater_than: 0 }, allow_nil: true
  validates :session_count, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  # How long one purchase of this plan lasts — computed from billing_period,
  # used by Memberships::Create/Renew to set expires_at.
  def duration_days
    DURATION_DAYS_BY_PERIOD.fetch(billing_period)
  end

  # No locations/activities attached means "grants access everywhere in the
  # company" — avoids forcing an owner to enumerate every location for a
  # simple all-access plan.
  def grants_access_to?(location:, activity:)
    location_ok = locations.empty? || locations.exists?(id: location.id)
    activity_ok = activities.empty? || activities.exists?(id: activity.id)
    location_ok && activity_ok
  end
end
