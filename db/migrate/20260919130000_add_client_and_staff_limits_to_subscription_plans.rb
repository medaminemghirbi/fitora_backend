class AddClientAndStaffLimitsToSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    # nil means unlimited, same convention as the existing max_locations.
    add_column :subscription_plans, :max_clients, :integer
    add_column :subscription_plans, :max_staff, :integer
  end
end
