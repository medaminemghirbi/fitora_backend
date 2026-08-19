class Payment < ApplicationRecord
  belongs_to :client
  belongs_to :company
  belongs_to :membership, optional: true
  belongs_to :booking, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :status, { paid: 0, partial: 1, refunded: 2, cancelled: 3 }
  enum :payment_method, { cash: 0, card: 1, bank_transfer: 2, other: 3 }

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :currency, presence: true
  validate :linked_to_exactly_one_payable

  scope :recent, -> { order(created_at: :desc) }

  private

  def linked_to_exactly_one_payable
    links = [ membership_id, booking_id ].compact
    errors.add(:base, "must be linked to a membership or booking") if links.empty?
  end
end
