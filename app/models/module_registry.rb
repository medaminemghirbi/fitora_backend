# The catalogue of capability modules the platform ships. A module bundles a
# slice of functionality (its permissions, its navigation, its models) that a
# company can switch on or off — WITHOUT the platform ever branching on a
# business "category". `core` is always on; everything else is opt-in per
# company via CompanyModule.
#
# Domain-specific behaviour lives behind a module here (fitness today;
# medical/legal/… later) so the generic core never has to know which trade a
# tenant is in.
module ModuleRegistry
  CORE_KEY = "core".freeze

  CATALOG = {
    "core" => {
      name: "Core",
      description: "Clients, team, documents, payments, reporting — the platform baseline.",
      permissions: %w[clients coaches payments reports company_library locations],
      always_on: true
    },
    "fitness" => {
      name: "Fitness",
      description: "Activities, class scheduling, bookings, attendance and memberships.",
      permissions: %w[activities sessions bookings checkin contracts],
      always_on: false
    }
    # medical / legal / beauty / … slot in here as they're built. Adding one
    # must not require touching the core.
  }.freeze

  KEYS = CATALOG.keys.freeze
  OPTIONAL_KEYS = CATALOG.reject { |_, m| m[:always_on] }.keys.freeze

  # Modules enabled for a brand-new company. Fitness is on by default so the
  # existing product is unchanged; a future onboarding step can let a company
  # pick a different set.
  DEFAULT_ENABLED = %w[core fitness].freeze

  def self.exists?(key)
    CATALOG.key?(key.to_s)
  end

  def self.always_on?(key)
    CATALOG.dig(key.to_s, :always_on) || false
  end

  # Every permission contributed by the given set of enabled module keys.
  def self.permissions_for(enabled_keys)
    keys = enabled_keys.map(&:to_s) | [ CORE_KEY ]
    keys.flat_map { |k| CATALOG.dig(k, :permissions) || [] }.uniq
  end
end
