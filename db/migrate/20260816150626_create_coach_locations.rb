class CreateCoachLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :coach_locations do |t|
      t.references :coach, null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true

      t.timestamps
    end

    add_index :coach_locations, [ :coach_id, :location_id ], unique: true
  end
end
