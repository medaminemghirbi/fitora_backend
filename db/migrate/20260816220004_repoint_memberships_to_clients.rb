class RepointMembershipsToClients < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :memberships, :users
    remove_index :memberships, name: "index_memberships_on_user_id"
    remove_index :memberships, name: "index_memberships_on_user_id_and_status"

    rename_column :memberships, :user_id, :client_id

    add_foreign_key :memberships, :clients
    add_index :memberships, :client_id
    add_index :memberships, [ :client_id, :status ]

    add_column :memberships, :discount, :decimal, precision: 10, scale: 2, null: false, default: 0
    add_column :memberships, :final_price, :decimal, precision: 10, scale: 2
    add_column :memberships, :payment_status, :integer, null: false, default: 0
    add_reference :memberships, :created_by, foreign_key: { to_table: :users }, index: true, null: true
  end
end
