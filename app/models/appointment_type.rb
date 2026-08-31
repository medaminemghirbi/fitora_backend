# A company-scoped kind of appointment — "Consultation", "Détartrage",
# "Visite technique" — carrying a default duration and a colour for the
# agenda. Managed from Settings. Part of the "appointments" module.
class AppointmentType < ApplicationRecord
  belongs_to :company
  has_many :appointments, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :duration_minutes, numericality: { greater_than: 0, less_than_or_equal_to: 24 * 60 }
  validates :color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex color like #4f46e5" }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:position, :name) }

  before_validation { self.color = "#4f46e5" if color.blank? }

  DEFAULTS = [
    { name: "Rendez-vous", duration_minutes: 30, color: "#4f46e5" },
    { name: "Première visite", duration_minutes: 45, color: "#0ea5e9" },
    { name: "Suivi", duration_minutes: 15, color: "#16a34a" }
  ].freeze

  def self.seed_defaults_for(company)
    DEFAULTS.each_with_index do |attrs, index|
      type = company.appointment_types.find_or_initialize_by(name: attrs[:name])
      next unless type.new_record?

      type.assign_attributes(attrs.merge(position: index))
      type.save!
    end
  end
end
