class CreateSessions < ActiveRecord::Migration[8.0]
  def up
    create_table :sessions do |t|
      t.references :activity, null: false, foreign_key: true, index: true
      t.references :location, null: false, foreign_key: true, index: true
      t.references :coach, foreign_key: true, index: true
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :capacity, null: false
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      # 0 = scheduled, 1 = cancelled, 2 = completed. This ordinal is baked into the
      # exclusion constraint below (Session::STATUSES) — do not reorder the enum.
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_index :sessions, :starts_at

    # Airtight, concurrency-safe guarantee that a coach can never have two
    # overlapping scheduled sessions, enforced by Postgres itself rather than
    # an app-level check-then-insert race.
    execute <<~SQL
      ALTER TABLE sessions
      ADD CONSTRAINT no_overlapping_coach_sessions
      EXCLUDE USING gist (
        coach_id WITH =,
        tsrange(starts_at, ends_at) WITH &&
      )
      WHERE (status = 0 AND coach_id IS NOT NULL)
    SQL
  end

  def down
    drop_table :sessions
  end
end
