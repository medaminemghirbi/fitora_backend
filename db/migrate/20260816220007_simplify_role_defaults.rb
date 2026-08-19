class SimplifyRoleDefaults < ActiveRecord::Migration[8.0]
  def change
    # Roles are being simplified in the model layer: users.role drops
    # "customer" (owner/staff/admin remain), staff_members.role drops the
    # org-scoped "admin" sub-role (manager/receptionist/coach remain — only
    # the owner ever has full org access now). No data to migrate (dev DB is
    # being wiped and reseeded), just resetting the defaults to match.
    change_column_default :users, :role, from: 0, to: 1 # staff
    change_column_default :staff_members, :role, from: 1, to: 0 # manager
  end
end
