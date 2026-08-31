# A company's on/off switch for one entry in the ModuleRegistry. Absence of
# a row means "not enabled" (except for always-on modules like core). Kept as
# a table rather than a JSON column so it's queryable and so enabling a
# module can later carry its own settings.
class CompanyModule < ApplicationRecord
  belongs_to :company

  validates :key, presence: true,
                  uniqueness: { scope: :company_id },
                  inclusion: { in: ModuleRegistry::KEYS }

  scope :enabled, -> { where(enabled: true) }

  def self.sync_defaults_for(company)
    ModuleRegistry::DEFAULT_ENABLED.each do |key|
      company.company_modules.find_or_create_by!(key: key) { |m| m.enabled = true }
    end
  end
end
