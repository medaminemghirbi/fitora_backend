class CreateRecurringSchedules < ActiveRecord::Migration[8.0]
  def change
    create_table :recurring_schedules do |t|
      t.references :activity, null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true
      t.references :coach, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      # Postgres native integer array, 0=Sunday..6=Saturday — no join table needed.
      t.integer :weekdays, array: true, null: false, default: []
      t.time :start_time, null: false
      # 0 = weekly (V2 priority), 1 = daily, 2 = monthly
      t.integer :recurrence_type, null: false, default: 0
      t.date :starts_on, null: false
      t.date :ends_on, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :recurring_schedules, :weekdays, using: :gin
  end
end
