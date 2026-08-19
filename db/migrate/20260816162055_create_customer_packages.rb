class CreateCustomerPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :customer_packages do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :package, null: false, foreign_key: true, index: true
      t.integer :remaining_credits, null: false, default: 0
      t.datetime :purchased_at
      t.datetime :expires_at
      # 0 = pending, 1 = active, 2 = expired, 3 = cancelled
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :customer_packages, [ :user_id, :status ]
  end
end
