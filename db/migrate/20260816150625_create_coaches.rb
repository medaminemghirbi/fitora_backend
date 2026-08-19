class CreateCoaches < ActiveRecord::Migration[8.0]
  def change
    create_table :coaches do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :first_name, null: false
      t.string :last_name, null: false
      t.string :email
      t.string :phone
      t.text :bio
      t.string :photo_url
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
