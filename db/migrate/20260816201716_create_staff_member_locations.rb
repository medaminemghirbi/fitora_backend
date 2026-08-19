class CreateStaffMemberLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :staff_member_locations do |t|
      t.references :staff_member, null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :staff_member_locations, [ :staff_member_id, :location_id ], unique: true, name: "index_staff_member_locations_unique"
  end
end
