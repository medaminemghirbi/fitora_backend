class Subscription < ApplicationRecord
  belongs_to :organization
  belongs_to :subscription_plan

  enum :status, { active: 0, inactive: 1, expired: 2, cancelled: 3 }

  validates :starts_at, presence: true
  validates :organization_id, uniqueness: true

  # expires_at doubles as the free-trial deadline: set to 14 days out at
  # signup (see Api::V1::OrganizationsController#create), and cleared to nil
  # the moment a platform admin manually assigns/renews a plan (see
  # Api::V1::Admin::OrganizationsController#update_subscription) — nil means
  # "not on a ticking clock," whether that's an active trial-free paid plan
  # or one the admin manages by hand. Once it passes, Api::V1::BaseController
  # locks every account in the organization except the owner.
  def locked?
    expires_at.present? && expires_at <= Time.current
  end

  def days_remaining
    return nil if expires_at.blank?

    [ (expires_at.to_date - Date.current).to_i, 0 ].max
  end
end
