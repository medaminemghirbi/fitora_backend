class CreateStaffMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :staff_members do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :coach, foreign_key: true, index: true
      # 0 = admin (org-scoped, distinct from User#role admin), 1 = manager,
      # 2 = coach, 3 = receptionist
      t.integer :role, null: false, default: 1
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
