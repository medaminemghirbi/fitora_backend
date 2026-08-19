class Company < ApplicationRecord
  belongs_to :owner, class_name: "User", inverse_of: :company

  has_many :locations, dependent: :destroy
  has_many :coaches, dependent: :destroy
  has_one :contract, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :membership_plans, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :staff_members, dependent: :destroy
  has_many :recurring_schedules, dependent: :destroy
  has_many :audit_logs, dependent: :destroy

  validates :name, presence: true
  validates :timezone, :currency, presence: true

  def current_plan
    contract&.contract_plan
  end

  # Every company has exactly one location — created automatically at
  # signup (see Api::V1::CompaniesController#create) and never a second
  # one. Activities, coaches, and staff all attach to it implicitly instead
  # of asking staff to pick a location that doesn't meaningfully vary.
  def location
    locations.first
  end
end
