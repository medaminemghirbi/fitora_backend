class CreatePackages < ActiveRecord::Migration[8.0]
  def change
    create_table :packages do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :activity, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.string :currency, null: false, default: "TND"
      t.integer :credits, null: false
      t.integer :validity_days, null: false, default: 60
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
