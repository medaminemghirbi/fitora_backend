class Activity < ApplicationRecord
  belongs_to :location

  has_many :sessions, dependent: :destroy
  has_many :contract_type_activities, dependent: :destroy
  has_many :contract_types, through: :contract_type_activities

  # "class" is a reserved Ruby word, so the CLASS activity type from the spec is
  # named group_class here (enum ordinal 2 is what's stored in the activity_type column).
  enum :activity_type, { open_access: 0, slot: 1, group_class: 2 }

  # Controls whether Bookings::Create requires a contract/payment. Defaults
  # to free so every V0 activity keeps booking instantly with no payment gate.
  enum :booking_mode, { free: 0, pay_per_booking: 1, contract_required: 2 }

  validates :name, presence: true
  validates :duration, numericality: { greater_than: 0 }
  validates :capacity, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }

  delegate :company, to: :location
end
