module Permissions
  # The single source of truth for "what can this login do" — used by the
  # /me/permissions and /bootstrap endpoints. Owners get every permission
  # their enabled modules expose; staff get their assigned Role's list
  # (intersected with what the enabled modules expose, so disabling a module
  # also hides its permissions); a platform admin gets none.
  class Resolve
    Result = Struct.new(:role, :permissions, keyword_init: true)

    def self.call(user:)
      new(user).call
    end

    def initialize(user)
      @user = user
    end

    def call
      return Result.new(role: nil, permissions: []) if user.admin?

      company = resolve_company
      available = company ? ModuleRegistry.permissions_for(company.enabled_module_keys) : Permission::ALL

      if user.owner?
        owner_role = company&.roles&.find_by(key: "owner")
        return Result.new(
          role: role_hash(owner_role) || { key: "owner", name: "Propriétaire" },
          permissions: (owner_role&.permissions || Permission::ALL) & available
        )
      end

      staff_member = user.staff_member
      Result.new(
        role: role_hash(staff_member&.assigned_role) ||
              (staff_member && { key: staff_member.role, name: staff_member.role.to_s.humanize }),
        permissions: (staff_member ? staff_member.permission_keys : []) & available
      )
    end

    private

    attr_reader :user

    def resolve_company
      user.company || user.staff_member&.company
    end

    def role_hash(role)
      return nil if role.nil?

      { key: role.key, name: role.name }
    end
  end
end
