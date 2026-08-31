class CreateCompanyModules < ActiveRecord::Migration[8.0]
  # Per-company on/off switches for ModuleRegistry entries. Backfills every
  # existing company with core + fitness enabled, so the current product is
  # unchanged.
  def up
    create_table :company_modules, id: :uuid do |t|
      t.references :company, type: :uuid, null: false, foreign_key: true, index: true
      t.string :key, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :company_modules, [ :company_id, :key ], unique: true

    say_with_time "enabling core + fitness for existing companies" do
      select_values("SELECT id FROM companies").each do |company_id|
        %w[core fitness].each do |key|
          execute(<<~SQL.squish)
            INSERT INTO company_modules (id, company_id, key, enabled, created_at, updated_at)
            VALUES (gen_random_uuid(), #{quote(company_id)}, #{quote(key)}, true, now(), now())
            ON CONFLICT (company_id, key) DO NOTHING
          SQL
        end
      end
    end
  end

  def down
    drop_table :company_modules
  end
end
