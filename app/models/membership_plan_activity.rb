class MembershipPlanActivity < ApplicationRecord
  belongs_to :membership_plan
  belongs_to :activity

  validates :activity_id, uniqueness: { scope: :membership_plan_id }
end
