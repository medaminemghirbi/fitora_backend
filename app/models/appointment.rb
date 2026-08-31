# A 1:1 appointment: a contact (Client) meets a staff member at a time, for
# a duration, with a status. The generic counterpart to the fitness module's
# Session (which is group/capacity based). Part of the "appointments" module.
class Appointment < ApplicationRecord
  belongs_to :company
  belongs_to :client
  belongs_to :staff_member, optional: true
  belongs_to :appointment_type, optional: true
  belongs_to :location, optional: true
  belongs_to :created_by, class_name: "User", optional: true

  enum :status, { scheduled: 0, confirmed: 1, completed: 2, cancelled: 3, no_show: 4 }

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts
  validate :associations_belong_to_company

  before_validation :apply_type_defaults, on: :create

  scope :active, -> { where.not(status: :cancelled) }
  scope :in_range, ->(from, to) { where("appointments.starts_at < ? AND appointments.ends_at > ?", to, from) }
  scope :for_day, ->(date) { where(starts_at: date.all_day) }
  scope :upcoming, -> { where("starts_at >= ?", Time.current).order(:starts_at) }
  scope :chronological, -> { order(:starts_at) }

  def label
    title.presence || appointment_type&.name || "Rendez-vous"
  end

  private

  # A fresh appointment created with just a type + start time gets its title
  # and end time filled from the type.
  def apply_type_defaults(now: Time.current)
    self.title = appointment_type.name if title.blank? && appointment_type
    if ends_at.blank? && starts_at.present?
      minutes = appointment_type&.duration_minutes || 30
      self.ends_at = starts_at + minutes.minutes
    end
  end

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?

    errors.add(:ends_at, "must be after the start time") if ends_at <= starts_at
  end

  def associations_belong_to_company
    errors.add(:client, "must belong to this company") if client && client.company_id != company_id
    errors.add(:staff_member, "must belong to this company") if staff_member && staff_member.company_id != company_id
    errors.add(:appointment_type, "must belong to this company") if appointment_type && appointment_type.company_id != company_id
  end
end
