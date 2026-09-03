class StaffMember < ApplicationRecord
  # Org-scoped role for a staff login. Only three values now — the owner is
  # never a StaffMember row (Company#owner) and always has full access,
  # so there's no "staff acting as owner" role to model here anymore.
  ROLES = { manager: 0, receptionist: 1, coach: 2 }.freeze

  # Legacy fallback only — kept for staff rows that predate the Role table
  # and haven't been backfilled (and for the CreateRoles migration's own
  # reference). Live permission resolution goes through #permission_keys,
  # which prefers the assigned Role. "checkin" covers attendance-marking
  # rights; "sessions" is specifically the right to *restructure* the
  # schedule — everyone can *view* the calendar, see BaseController#require_staff!.
  CAPABILITIES = {
    manager: %i[locations activities coaches sessions bookings clients contracts payments reports checkin company_library],
    receptionist: %i[bookings clients contracts payments checkin reports coaches],
    coach: %i[checkin]
  }.freeze

  belongs_to :user
  belongs_to :company
  belongs_to :coach, optional: true
  # The configurable role this staff login is assigned to. Optional during
  # the migration window; #permission_keys falls back to CAPABILITIES when
  # it's nil.
  belongs_to :assigned_role, class_name: "Role", foreign_key: :role_id, optional: true, inverse_of: :staff_members

  has_many :staff_member_locations, dependent: :destroy
  has_many :locations, through: :staff_member_locations
  has_many :work_contracts, dependent: :destroy
  has_many :leave_requests, dependent: :destroy
  has_many :appointments, dependent: :nullify

  enum :role, ROLES

  # During the migration window the legacy `role` enum is still the source of
  # truth: keep `assigned_role` pointing at the built-in Role that matches it,
  # so new and edited staff rows resolve permissions through the Role table
  # like everything else. Phase 2 lets a company assign custom roles and
  # flips this the other way round.
  before_validation :sync_assigned_role_from_enum

  validates :user_id, uniqueness: true
  validate :coach_only_for_coach_role
  validate :coach_belongs_to_same_company

  scope :active, -> { where(active: true) }

  def can?(capability)
    permission_keys.include?(capability.to_s)
  end

  def full_name
    user&.full_name
  end

  # True on the person's birthday (day + month), any year.
  def birthday_today?(on: Date.current)
    birthdate.present? && birthdate.strftime("%m-%d") == on.strftime("%m-%d")
  end

  # The resolved permission list for this staff login: the assigned Role's
  # permissions, or — for rows not yet linked to a Role — the legacy
  # capability map for the enum value.
  def permission_keys
    return assigned_role.permissions if assigned_role

    CAPABILITIES.fetch(role.to_sym, []).map(&:to_s)
  end

  # The employee's live employment contract, if any — the active one, else
  # the most recent. Feeds the RH pré-fiche de paie and the CP balance.
  def current_work_contract
    work_contracts.active.order(starts_on: :desc).first || work_contracts.order(starts_on: :desc).first
  end

  # Paid-leave (CP) balance for a calendar year: annual entitlement from the
  # current work contract, minus approved paid leave taken that year.
  def paid_leave_balance(year: Date.current.year)
    entitlement = current_work_contract&.paid_leave_days_per_year.to_f
    taken = leave_requests.counts_against_balance.in_year(year).sum(:days_count).to_f

    { year: year, entitlement: entitlement, taken: taken, balance: (entitlement - taken).round(1) }
  end

  private

  def sync_assigned_role_from_enum
    return if company_id.blank? || role.blank?

    match = company.roles.find_by(key: role.to_s)
    self.assigned_role = match if match && role_id != match.id
  end

  def coach_only_for_coach_role
    errors.add(:coach, "can only be set for the coach role") if coach.present? && !coach?
  end

  def coach_belongs_to_same_company
    return if coach.blank?

    errors.add(:coach, "must belong to the same company") if coach.company_id != company_id
  end
end
