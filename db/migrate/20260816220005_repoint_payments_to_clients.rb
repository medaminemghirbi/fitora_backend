class RepointPaymentsToClients < ActiveRecord::Migration[8.0]
  def change
    remove_foreign_key :payments, :users
    remove_foreign_key :payments, :promotions
    remove_index :payments, name: "index_payments_on_user_id"
    remove_index :payments, name: "index_payments_on_payable"
    remove_index :payments, name: "index_payments_on_promotion_id"
    remove_index :payments, name: "index_payments_on_provider_and_transaction_id"

    remove_column :payments, :payable_type, :string
    remove_column :payments, :payable_id, :bigint
    remove_column :payments, :provider, :string
    remove_column :payments, :provider_transaction_id, :string
    remove_column :payments, :promotion_id, :bigint
    remove_column :payments, :discount_amount, :decimal, precision: 10, scale: 2
    remove_column :payments, :metadata, :jsonb

    rename_column :payments, :user_id, :client_id
    add_foreign_key :payments, :clients
    add_index :payments, :client_id

    add_reference :payments, :membership, foreign_key: true, index: true, null: true
    add_reference :payments, :booking, foreign_key: true, index: true, null: true
    add_column :payments, :method, :integer, null: false, default: 0
    add_column :payments, :notes, :text
    add_reference :payments, :created_by, foreign_key: { to_table: :users }, index: true, null: true
  end
end
