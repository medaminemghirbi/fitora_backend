class AddUniqueIndexToOrganizationsOwner < ActiveRecord::Migration[8.0]
  def change
    remove_index :organizations, :owner_id
    add_index :organizations, :owner_id, unique: true
  end
end
