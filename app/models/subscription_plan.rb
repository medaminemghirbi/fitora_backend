class SubscriptionPlan < ApplicationRecord
  enum :billing_period, { monthly: 0, yearly: 1 }

  has_many :subscriptions, dependent: :restrict_with_error

  validates :name, :code, presence: true
  validates :code, uniqueness: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :max_locations, numericality: { greater_than: 0 }, allow_nil: true

  scope :active, -> { where(active: true) }

  # nil max_locations means unlimited locations.
  def unlimited_locations?
    max_locations.nil?
  end
end
