class CreateMemberships < ActiveRecord::Migration[8.0]
  def change
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :membership_plan, null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      # 0 = pending, 1 = active, 2 = expired, 3 = cancelled
      t.integer :status, null: false, default: 0
      t.datetime :starts_at
      t.datetime :expires_at
      t.integer :remaining_bookings
      t.boolean :auto_renew, null: false, default: false

      t.timestamps
    end

    add_index :memberships, [ :user_id, :status ]
  end
end
