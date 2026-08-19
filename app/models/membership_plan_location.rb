class MembershipPlanLocation < ApplicationRecord
  belongs_to :membership_plan
  belongs_to :location

  validates :location_id, uniqueness: { scope: :membership_plan_id }
end
