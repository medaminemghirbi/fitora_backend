class CreatePromotions < ActiveRecord::Migration[8.0]
  def change
    create_table :promotions do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :code, null: false
      # 0 = percentage, 1 = fixed_amount
      t.integer :promotion_type, null: false, default: 0
      t.decimal :value, precision: 10, scale: 2, null: false
      t.datetime :starts_at
      t.datetime :expires_at
      t.integer :max_uses
      t.integer :usage_count, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :promotions, [ :organization_id, :code ], unique: true
  end
end
