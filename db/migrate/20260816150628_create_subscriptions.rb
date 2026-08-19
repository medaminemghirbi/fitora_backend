class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :organization, null: false, foreign_key: true, index: { unique: true }
      t.references :subscription_plan, null: false, foreign_key: true, index: true
      t.integer :status, null: false, default: 0
      t.datetime :starts_at, null: false
      t.datetime :expires_at
      t.boolean :auto_renew, null: false, default: false

      t.timestamps
    end
  end
end
