class CreateMembershipPlanLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :membership_plan_locations do |t|
      t.references :membership_plan, null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :membership_plan_locations, [ :membership_plan_id, :location_id ], unique: true, name: "index_plan_locations_unique"
  end
end
