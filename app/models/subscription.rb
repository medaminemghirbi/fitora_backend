class Subscription < ApplicationRecord
  belongs_to :company

  enum :status, { active: 0, inactive: 1, expired: 2, cancelled: 3 }

  validates :starts_at, presence: true
  validates :company_id, uniqueness: true

  # No plans, no tiers — this is just the company's access status with
  # Gerily, set by hand by a platform admin (Api::V1::Admin::CompaniesController#update_subscription).
  # expires_at doubles as the free-trial deadline: set to 14 days out at
  # signup (see Api::V1::CompaniesController#create), and cleared to nil
  # the moment an admin manually grants ongoing access — nil means "not on
  # a ticking clock." Once it passes, or the moment status is anything but
  # active (admin marks it inactive/expired/cancelled),
  # Api::V1::BaseController locks every account in the company except the owner.
  def locked?
    return true unless active?

    expires_at.present? && expires_at <= Time.current
  end

  def days_remaining
    return nil if expires_at.blank?

    [ (expires_at.to_date - Date.current).to_i, 0 ].max
  end
end
