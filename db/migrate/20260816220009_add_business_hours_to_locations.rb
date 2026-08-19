class AddBusinessHoursToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :business_hours_start, :time, null: false, default: "2000-01-01 06:00:00"
    add_column :locations, :business_hours_end, :time, null: false, default: "2000-01-01 22:00:00"
  end
end
