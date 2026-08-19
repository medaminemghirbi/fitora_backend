class CreateReviews < ActiveRecord::Migration[8.0]
  def up
    create_table :reviews do |t|
      t.references :user, null: false, foreign_key: true, index: true
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :session, null: false, foreign_key: true, index: true
      t.references :booking, null: false, foreign_key: true, index: false
      t.integer :rating, null: false
      t.text :comment
      t.boolean :visible, null: false, default: true

      t.timestamps
    end

    add_index :reviews, :booking_id, unique: true
    execute "ALTER TABLE reviews ADD CONSTRAINT rating_between_1_and_5 CHECK (rating BETWEEN 1 AND 5)"
  end

  def down
    drop_table :reviews
  end
end
