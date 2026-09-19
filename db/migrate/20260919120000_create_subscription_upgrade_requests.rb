class CreateSubscriptionUpgradeRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_upgrade_requests do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :subscription_plan, null: false, foreign_key: true, index: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }, index: true
      # 0 = cash, 1 = card, 2 = bank_transfer — mirrors Payment#payment_method
      t.integer :payment_method, null: false
      # 0 = pending, 1 = approved, 2 = rejected
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
