class Client < ApplicationRecord
  belongs_to :organization

  has_many :bookings, dependent: :destroy
  has_many :memberships, dependent: :destroy
  has_many :client_packages, dependent: :destroy
  has_many :payments, dependent: :destroy

  before_validation { self.email = email.to_s.downcase.strip if email.present? }
  before_validation { self.joined_at ||= Time.current }

  validates :first_name, :last_name, :phone, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :search, ->(term) {
    return all if term.blank?

    sanitized = "%#{term.strip}%"
    where("first_name ILIKE :t OR last_name ILIKE :t OR phone ILIKE :t OR email ILIKE :t", t: sanitized)
  }

  def full_name
    "#{first_name} #{last_name}"
  end

  def current_membership
    memberships.currently_active.order(expires_at: :desc).first
  end

  # What's still owed: unpaid/partial bookings and memberships, net of any
  # payments already recorded against them. Not a full accounting ledger —
  # just enough to flag a client with a balance due.
  def outstanding_balance
    owed = bookings.where(payment_status: %i[unpaid partial]).sum(:amount) +
           memberships.where(payment_status: %i[unpaid partial]).sum(:final_price)
    received = payments.paid.where.not(booking_id: nil).sum(:amount) +
               payments.paid.where.not(membership_id: nil).sum(:amount)
    [ owed - received, 0 ].max
  end

  def attendance_rate
    records = AttendanceRecord.joins(:booking).where(bookings: { client_id: id })
    total = records.count
    return nil if total.zero?

    (records.present.count.to_f / total * 100).round
  end
end
