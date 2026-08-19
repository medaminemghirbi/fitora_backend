class RepointBookingsToClients < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :bookings, :users
    remove_foreign_key :bookings, :client_packages
    remove_index :bookings, name: "index_bookings_on_user_id"
    remove_index :bookings, name: "index_bookings_on_session_id_and_user_id_when_held"
    remove_index :bookings, name: "index_bookings_on_customer_package_id"

    rename_column :bookings, :user_id, :client_id
    rename_column :bookings, :customer_package_id, :client_package_id

    add_foreign_key :bookings, :clients
    add_foreign_key :bookings, :client_packages
    add_index :bookings, :client_id
    add_index :bookings, :client_package_id
    # "Held" now means confirmed only (status 0) — the pending_payment status
    # this index used to also cover is being dropped; booking creation no
    # longer has an online-payment-pending phase.
    add_index :bookings, [ :session_id, :client_id ], unique: true, where: "(status = 0)",
                                                        name: "index_bookings_on_session_id_and_client_id_when_held"

    add_column :bookings, :payment_status, :integer, null: false, default: 0
  end
end
