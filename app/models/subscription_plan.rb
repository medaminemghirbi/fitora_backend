class SubscriptionPlan < ApplicationRecord
  enum :billing_period, { monthly: 0, yearly: 1 }

  has_many :subscriptions, dependent: :restrict_with_error

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :max_locations, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_clients, numericality: { greater_than: 0 }, allow_nil: true
  validates :max_staff, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  # nil max_locations means unlimited locations.
  def unlimited_locations?
    max_locations.nil?
  end

  # nil max_clients/max_staff means unlimited — same convention as
  # max_locations. Used at creation time (ClientsController#create,
  # StaffController#create) to decide whether the organization has room for
  # one more before it's actually saved.
  def client_limit_reached?(current_count)
    max_clients.present? && current_count >= max_clients
  end

  def staff_limit_reached?(current_count)
    max_staff.present? && current_count >= max_staff
  end

  # Gate for every Premium+ perk (the styled .xlsx export, PDF receipts, SMS
  # reminders...) — Basic doesn't get any of them, the free trial
  # deliberately stays ungated like every other feature during the 14 days.
  def premium?
    code != "basic"
  end
end
