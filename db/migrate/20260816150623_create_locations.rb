class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.string :phone
      t.string :email
      t.string :address
      t.string :city
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :timezone, null: false, default: "Africa/Tunis"
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
