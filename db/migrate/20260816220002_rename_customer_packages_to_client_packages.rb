class RenameCustomerPackagesToClientPackages < ActiveRecord::Migration[8.0]
  def change
    rename_table :customer_packages, :client_packages

    remove_foreign_key :client_packages, :users
    remove_index :client_packages, name: "index_client_packages_on_user_id"
    remove_index :client_packages, name: "index_client_packages_on_user_id_and_status"

    rename_column :client_packages, :user_id, :client_id

    add_foreign_key :client_packages, :clients
    add_index :client_packages, :client_id
    add_index :client_packages, [ :client_id, :status ]
  end
end
