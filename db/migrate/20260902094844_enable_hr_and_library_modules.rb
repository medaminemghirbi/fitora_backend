class EnableHrAndLibraryModules < ActiveRecord::Migration[8.0]
  # `hr` and `library` split "team management" and "document library" out of
  # `core` into their own priced modules. Enable them for every existing
  # company so nothing they already use disappears; an admin can turn them
  # off per company from the console afterwards.
  def up
    say_with_time "Enabling hr + library modules for existing companies" do
      Company.find_each do |company|
        %w[hr library].each do |key|
          company.company_modules.find_or_create_by!(key: key) { |m| m.enabled = true }
        end
      end
    end
  end

  def down
    CompanyModule.where(key: %w[hr library]).delete_all
  end
end
