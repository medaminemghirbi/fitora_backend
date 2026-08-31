class AddNavLabelsToCompanies < ActiveRecord::Migration[8.0]
  # Per-company navigation label overrides, keyed by the frontend's nav
  # labelKey (e.g. {"nav.clients": "Patients", "nav.contracts": "Dossiers"}).
  # Empty by default — the company keeps the shipped labels until it renames
  # them from Settings.
  def change
    add_column :companies, :nav_labels, :jsonb, null: false, default: {}
  end
end
