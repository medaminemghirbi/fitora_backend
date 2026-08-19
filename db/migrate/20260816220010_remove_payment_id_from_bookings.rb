class RemovePaymentIdFromBookings < ActiveRecord::Migration[8.0]
  def change
    # Redundant now that payments.booking_id exists — a booking's payment
    # history is a has_many (partial payments accumulate toward the total),
    # not a single belongs_to, so the FK lives on payments only.
    remove_foreign_key :bookings, :payments
    remove_index :bookings, name: "index_bookings_on_payment_id"
    remove_column :bookings, :payment_id, :bigint
  end
end
