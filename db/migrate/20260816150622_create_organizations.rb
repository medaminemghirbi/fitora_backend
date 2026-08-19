class CreateOrganizations < ActiveRecord::Migration[8.0]
  def change
    create_table :organizations do |t|
      t.references :owner, null: false, foreign_key: { to_table: :users }, index: true
      t.string :name, null: false
      t.text :description
      t.string :phone
      t.string :email
      t.string :country
      t.string :city
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :address
      t.string :timezone, null: false, default: "Africa/Tunis"
      t.string :currency, null: false, default: "TND"
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
