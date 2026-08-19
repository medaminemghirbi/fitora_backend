class RemovePriceFromActivities < ActiveRecord::Migration[8.0]
  def change
    remove_column :activities, :price, :decimal, precision: 10, scale: 2, null: false, default: 0
  end
end
