class AddV1FieldsToBookings < ActiveRecord::Migration[8.0]
  def up
    add_reference :bookings, :membership, foreign_key: true, index: true
    add_reference :bookings, :customer_package, foreign_key: true, index: true
    add_reference :bookings, :payment, foreign_key: true, index: true

    # Widen the V0 duplicate-booking guard to also cover pending_payment (4),
    # the new status introduced for pay-per-booking checkout — a customer must
    # not be able to hold two non-terminal (confirmed or awaiting-payment)
    # bookings for the same session.
    execute "DROP INDEX index_bookings_on_session_id_and_user_id_when_confirmed"
    execute <<~SQL
      CREATE UNIQUE INDEX index_bookings_on_session_id_and_user_id_when_held
      ON bookings (session_id, user_id)
      WHERE (status IN (0, 4))
    SQL
  end

  def down
    execute "DROP INDEX index_bookings_on_session_id_and_user_id_when_held"
    execute <<~SQL
      CREATE UNIQUE INDEX index_bookings_on_session_id_and_user_id_when_confirmed
      ON bookings (session_id, user_id)
      WHERE (status = 0)
    SQL

    remove_reference :bookings, :payment
    remove_reference :bookings, :customer_package
    remove_reference :bookings, :membership
  end
end
