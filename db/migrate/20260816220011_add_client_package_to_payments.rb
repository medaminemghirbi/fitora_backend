class AddClientPackageToPayments < ActiveRecord::Migration[8.0]
  def change
    add_reference :payments, :client_package, foreign_key: true, index: true, null: true
  end
end
