class AddIndustryToCompanies < ActiveRecord::Migration[8.0]
  # Free-text label for the trade the company picked at signup (its industry
  # PRESET). Nullable, display-only: nothing in the app branches on it — it
  # exists so the owner can see and re-apply a preset. Existing companies get
  # "fitness" since that's the only product that shipped before this.
  def up
    add_column :companies, :industry, :string

    execute("UPDATE companies SET industry = 'fitness' WHERE industry IS NULL")
  end

  def down
    remove_column :companies, :industry
  end
end
