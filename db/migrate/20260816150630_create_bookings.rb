class CreateBookings < ActiveRecord::Migration[8.0]
  def up
    create_table :bookings do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :session, null: false, foreign_key: true, index: true
      # 0 = confirmed, 1 = cancelled, 2 = completed, 3 = no_show. This ordinal is
      # baked into the partial unique index below — do not reorder the enum.
      t.integer :status, null: false, default: 0
      t.decimal :amount, precision: 10, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "TND"

      t.timestamps
    end

    # A user can only hold one CONFIRMED booking per session at a time. This is
    # the DB-level backstop behind Bookings::Create's transaction + row lock.
    execute <<~SQL
      CREATE UNIQUE INDEX index_bookings_on_session_id_and_user_id_when_confirmed
      ON bookings (session_id, user_id)
      WHERE (status = 0)
    SQL
  end

  def down
    drop_table :bookings
  end
end
