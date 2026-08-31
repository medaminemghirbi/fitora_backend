# A company-scoped, editable set of permissions that staff logins are
# assigned to. Every company starts with four built-in roles (owner,
# manager, receptionist, coach) seeded from DEFAULTS so behaviour is
# unchanged from the old hard-coded StaffMember::CAPABILITIES hash; a
# company can rename them, change their permissions, or add its own
# ("Doctor", "Assistant", …) without any code change.
#
# The built-in roles keep their `key` (SYSTEM_KEYS) so the backend and
# frontend can still recognise them; custom roles get a slugified key.
class Role < ApplicationRecord
  belongs_to :company
  has_many :staff_members, foreign_key: :role_id, inverse_of: :assigned_role, dependent: :restrict_with_error

  SYSTEM_KEYS = %w[owner manager receptionist coach].freeze

  DEFAULTS = {
    "owner" => {
      name: "Propriétaire",
      permissions: Permission::ALL
    },
    "manager" => {
      name: "Manager",
      permissions: %w[locations activities coaches sessions bookings clients contracts payments reports checkin company_library]
    },
    "receptionist" => {
      name: "Réception",
      permissions: %w[bookings clients contracts payments checkin reports coaches]
    },
    "coach" => {
      name: "Coach",
      permissions: %w[checkin]
    }
  }.freeze

  before_validation :normalise

  validates :key, presence: true, uniqueness: { scope: :company_id, case_sensitive: false }
  validates :name, presence: true

  scope :ordered, -> { order(:position, :name) }

  # A built-in role can be re-permissioned and renamed but not deleted or
  # re-keyed; a custom role can be deleted once nothing is assigned to it.
  def builtin?
    self[:builtin]
  end

  def deletable?
    !builtin? && staff_members.none?
  end

  def self.seed_defaults_for(company)
    DEFAULTS.each_with_index do |(key, attrs), index|
      role = company.roles.find_or_initialize_by(key: key)
      if role.new_record?
        role.name = attrs[:name]
        role.permissions = attrs[:permissions]
      end
      role.builtin = true
      role.position = index
      role.save!
    end
  end

  private

  def normalise
    self.permissions = Permission.sanitize(permissions)
    self.key = key.to_s.strip.parameterize(separator: "_").presence
  end
end
