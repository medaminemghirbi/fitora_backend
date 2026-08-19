class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true, index: true
      # "type" is a reserved Rails STI column, hence notification_type.
      t.string :notification_type, null: false
      t.string :title, null: false
      t.text :message
      t.datetime :read_at
      t.jsonb :data, null: false, default: {}

      t.timestamps
    end

    add_index :notifications, [ :user_id, :read_at ]
  end
end
