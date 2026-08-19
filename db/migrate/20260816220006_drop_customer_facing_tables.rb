class DropCustomerFacingTables < ActiveRecord::Migration[8.0]
  def up
    drop_table :reviews
    drop_table :notifications
    drop_table :promotions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
