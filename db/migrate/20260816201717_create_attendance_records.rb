class CreateAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_records do |t|
      t.references :booking, null: false, foreign_key: true, index: { unique: true }
      # 0 = present, 1 = absent, 2 = late, 3 = no_show
      t.integer :status, null: false, default: 0
      t.datetime :checked_in_at
      t.datetime :checked_out_at
      t.references :marked_by, foreign_key: { to_table: :users }, index: true

      t.timestamps
    end
  end
end
