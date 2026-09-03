class CreatePlatformModulePrices < ActiveRecord::Migration[8.0]
  def change
    create_table :platform_module_prices, id: :uuid do |t|
      # One of ModuleRegistry::OPTIONAL_KEYS. The platform-wide price the
      # admin charges for that module; a company's monthly total is the sum
      # of the prices of the modules it has enabled.
      t.string :key, null: false
      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "TND"
      # Whether the module is offered for sale at all — a soft on/off for the
      # catalogue that doesn't touch any company's existing access.
      t.boolean :active, null: false, default: true
      t.timestamps
    end
    add_index :platform_module_prices, :key, unique: true

    reversible do |dir|
      dir.up do
        ModuleRegistry::OPTIONAL_KEYS.each do |key|
          execute <<~SQL.squish
            INSERT INTO platform_module_prices (id, key, price_cents, currency, active, created_at, updated_at)
            VALUES (gen_random_uuid(), #{connection.quote(key)}, #{ModuleRegistry.default_price_cents(key).to_i}, 'TND', true, now(), now())
          SQL
        end
      end
    end
  end
end
