class CreateActivities < ActiveRecord::Migration[8.0]
  def change
    create_table :activities do |t|
      t.references :location, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.text :description
      t.integer :activity_type, null: false, default: 0
      t.integer :duration, null: false
      t.integer :capacity, null: false, default: 1
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :active, null: false, default: true

      t.timestamps
    end
  end
end
