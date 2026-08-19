class RenamePaymentMethodColumn < ActiveRecord::Migration[8.0]
  def change
    # "method" collides with Ruby's Kernel#method (reflection), which Rails'
    # enum-generated getter silently overrides — breaks Object#method on
    # every Payment instance. Renaming avoids the collision entirely.
    rename_column :payments, :method, :payment_method
  end
end
