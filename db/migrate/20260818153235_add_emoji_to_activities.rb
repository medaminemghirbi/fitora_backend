class AddEmojiToActivities < ActiveRecord::Migration[8.0]
  def change
    add_column :activities, :emoji, :string
  end
end
