class CreateSubscriptionPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_plans do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.integer :max_locations
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.integer :billing_period, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :subscription_plans, :code, unique: true
  end
end
