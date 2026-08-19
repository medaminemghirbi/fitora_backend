class CreateClients < ActiveRecord::Migration[8.0]
  def change
    create_table :clients do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.date :date_of_birth
      t.string :gender
      t.string :address
      t.string :emergency_contact_name
      t.string :emergency_contact_phone
      t.text :notes
      t.boolean :active, null: false, default: true
      t.datetime :joined_at, null: false

      t.timestamps
    end

    add_index :clients, [ :organization_id, :first_name, :last_name ]
  end
end
