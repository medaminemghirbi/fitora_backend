class CreateMembershipPlans < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_plans do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "TND"
      t.integer :duration_days, null: false, default: 30
      t.boolean :unlimited_bookings, null: false, default: false
      t.integer :booking_limit
      t.boolean :priority_booking, null: false, default: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
