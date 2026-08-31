class StaffMember < ApplicationRecord
  # Org-scoped role for a staff login. Only three values now — the owner is
  # never a StaffMember row (Company#owner) and always has full access,
  # so there's no "staff acting as owner" role to model here anymore.
  ROLES = { manager: 0, receptionist: 1, coach: 2 }.freeze

  # "checkin" covers attendance-marking rights (used by manager, receptionist,
  # and coach alike); "sessions" is specifically the right to *restructure*
  # the schedule (create/edit/cancel sessions) — everyone can *view* the
  # calendar regardless of capability, see BaseController#require_staff!.
  CAPABILITIES = {
    manager: %i[locations activities coaches sessions bookings clients contracts payments reports checkin company_library],
    receptionist: %i[bookings clients contracts payments checkin reports coaches],
    coach: %i[checkin]
  }.freeze

  belongs_to :user
  belongs_to :company
  belongs_to :coach, optional: true

  has_many :staff_member_locations, dependent: :destroy
  has_many :locations, through: :staff_member_locations
  has_many :work_contracts, dependent: :destroy
  has_many :leave_requests, dependent: :destroy

  enum :role, ROLES

  validates :user_id, uniqueness: true
  validate :coach_only_for_coach_role
  validate :coach_belongs_to_same_company

  scope :active, -> { where(active: true) }

  def can?(capability)
    CAPABILITIES.fetch(role.to_sym, []).include?(capability.to_sym)
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

  def coach_only_for_coach_role
    errors.add(:coach, "can only be set for the coach role") if coach.present? && !coach?
  end

  def coach_belongs_to_same_company
    return if coach.blank?

    errors.add(:coach, "must belong to the same company") if coach.company_id != company_id
  end
end
