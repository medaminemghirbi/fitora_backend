# Platform-wide price for one optional capability module. There is exactly
# one row per ModuleRegistry::OPTIONAL_KEYS (seeded on migrate). A company's
# monthly subscription total is the sum of the prices of its enabled modules
# whose price row is `active`. No invoicing here — payment is handled outside
# the app; the admin just records access.
class PlatformModulePrice < ApplicationRecord
  validates :key, presence: true, uniqueness: true, inclusion: { in: ModuleRegistry::OPTIONAL_KEYS }
  validates :price_cents, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :currency, presence: true

  scope :active, -> { where(active: true) }

  # Full priced catalogue in registry order, creating any missing rows from
  # the registry defaults so a newly-added module shows up without a manual
  # backfill.
  def self.catalog
    ModuleRegistry::OPTIONAL_KEYS.map do |key|
      find_or_create_by!(key: key) do |row|
        row.price_cents = ModuleRegistry.default_price_cents(key)
      end
    end
  end

  def self.for(key)
    catalog.find { |row| row.key == key.to_s }
  end

  # Monthly total for a set of enabled optional module keys.
  def self.monthly_total_cents(enabled_keys)
    keys = enabled_keys.map(&:to_s)
    active.where(key: keys).sum(:price_cents)
  end

  def name
    ModuleRegistry::CATALOG.dig(key, :name) || key.humanize
  end

  def description
    ModuleRegistry::CATALOG.dig(key, :description)
  end
end
