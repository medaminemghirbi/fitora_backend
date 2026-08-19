class CreatePayments < ActiveRecord::Migration[8.0]
  def up
    create_table :payments do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :payable, polymorphic: true, null: false, index: true
      t.string :provider, null: false
      t.string :provider_transaction_id
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :currency, null: false, default: "TND"
      # 0 = pending, 1 = paid, 2 = failed, 3 = refunded, 4 = cancelled
      t.integer :status, null: false, default: 0
      t.datetime :paid_at
      t.references :promotion, foreign_key: true, index: true
      t.decimal :discount_amount, precision: 10, scale: 2, null: false, default: 0
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    # Backstop against a webhook/confirmation being processed twice for the
    # same provider transaction — Payments::Confirm is the primary guard, this
    # is the DB-level safety net.
    execute <<~SQL
      CREATE UNIQUE INDEX index_payments_on_provider_and_transaction_id
      ON payments (provider, provider_transaction_id)
      WHERE (provider_transaction_id IS NOT NULL)
    SQL
  end

  def down
    drop_table :payments
  end
end
