class StaffMember < ApplicationRecord
  # Org-scoped role for a staff login. Only three values now — the owner is
  # never a StaffMember row (Organization#owner) and always has full access,
  # so there's no "staff acting as owner" role to model here anymore.
  ROLES = { manager: 0, receptionist: 1, coach: 2 }.freeze

  # "checkin" covers attendance-marking rights (used by manager, receptionist,
  # and coach alike); "sessions" is specifically the right to *restructure*
  # the schedule (create/edit/cancel sessions) — everyone can *view* the
  # calendar regardless of capability, see BaseController#require_staff!.
  CAPABILITIES = {
    manager: %i[locations activities coaches sessions bookings clients memberships payments reports checkin],
    receptionist: %i[bookings clients memberships payments checkin reports],
    coach: %i[checkin]
  }.freeze

  belongs_to :user
  belongs_to :organization
  belongs_to :coach, optional: true

  has_many :staff_member_locations, dependent: :destroy
  has_many :locations, through: :staff_member_locations

  enum :role, ROLES

  validates :user_id, uniqueness: true
  validate :coach_only_for_coach_role
  validate :coach_belongs_to_same_organization

  scope :active, -> { where(active: true) }

  def can?(capability)
    CAPABILITIES.fetch(role.to_sym, []).include?(capability.to_sym)
  end

  private

  def coach_only_for_coach_role
    errors.add(:coach, "can only be set for the coach role") if coach.present? && !coach?
  end

  def coach_belongs_to_same_organization
    return if coach.blank?

    errors.add(:coach, "must belong to the same organization") if coach.organization_id != organization_id
  end
end
