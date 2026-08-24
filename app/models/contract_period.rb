class ContractPeriod < ApplicationRecord
  belongs_to :contract
  has_many :bookings, dependent: :nullify
  has_many :payments, dependent: :nullify

  enum :status, { pending: 0, active: 1, expired: 2, cancelled: 3 }
  enum :payment_status, { unpaid: 0, partial: 1, paid: 2 }

  validates :starts_at, presence: true, if: :active?
  validates :discount, numericality: { greater_than_or_equal_to: 0 }

  before_validation :compute_final_price

  scope :currently_active, -> { active.where("expires_at IS NULL OR expires_at >= ?", Time.current) }
  scope :expiring_soon, ->(within: 7.days) { currently_active.where(expires_at: Time.current..Time.current + within) }

  private

  def compute_final_price
    plan = contract&.contract_type
    return if plan.blank?

    self.final_price = [ plan.price - discount.to_f, 0 ].max
  end
end
