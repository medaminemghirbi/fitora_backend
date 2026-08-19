class MembershipPlan < ApplicationRecord
  belongs_to :organization

  has_many :membership_plan_locations, dependent: :destroy
  has_many :locations, through: :membership_plan_locations
  has_many :membership_plan_activities, dependent: :destroy
  has_many :activities, through: :membership_plan_activities
  has_many :memberships, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :duration_days, numericality: { greater_than: 0 }
  validates :booking_limit, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  # No locations/activities attached means "grants access everywhere in the
  # organization" — avoids forcing an owner to enumerate every location for a
  # simple all-access plan.
  def grants_access_to?(location:, activity:)
    location_ok = locations.empty? || locations.exists?(id: location.id)
    activity_ok = activities.empty? || activities.exists?(id: activity.id)
    location_ok && activity_ok
  end
end
