class Contract < ApplicationRecord
  belongs_to :company
  belongs_to :contract_plan

  enum :status, { active: 0, inactive: 1, expired: 2, cancelled: 3 }

  validates :starts_at, presence: true
  validates :company_id, uniqueness: true

  # expires_at doubles as the free-trial deadline: set to 14 days out at
  # signup (see Api::V1::CompaniesController#create), and cleared to nil
  # the moment a platform admin manually assigns/renews a plan (see
  # Api::V1::Admin::CompaniesController#update_contract) — nil means
  # "not on a ticking clock," whether that's an active trial-free paid plan
  # or one the admin manages by hand. Once it passes, Api::V1::BaseController
  # locks every account in the company except the owner.
  def locked?
    expires_at.present? && expires_at <= Time.current
  end

  def days_remaining
    return nil if expires_at.blank?

    [ (expires_at.to_date - Date.current).to_i, 0 ].max
  end
end
