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
      description: "Clients, paiements, tableau de bord et réglages — la base de la plateforme.",
      permissions: %w[clients payments reports locations],
      always_on: true,
      default_price_cents: 0
    },
    "fitness" => {
      name: "Fitness",
      description: "Activités, calendrier, réservations, présences et contrats d'entraînement.",
      permissions: %w[activities sessions bookings checkin contracts],
      always_on: false,
      default_price_cents: 6000
    },
    "appointments" => {
      name: "Rendez-vous",
      description: "Agenda, créneaux et prise de rendez-vous individuels — pour le médical, la beauté, le juridique…",
      permissions: %w[appointments],
      always_on: false,
      default_price_cents: 4000
    },
    "hr" => {
      name: "RH & paie",
      description: "Équipe, contrats de travail, types d'absence et pré-fiche de paie.",
      permissions: %w[coaches],
      always_on: false,
      default_price_cents: 2500
    },
    "library" => {
      name: "Bibliothèque d'entreprise",
      description: "Classement des documents de l'entreprise par dossier (assurances, juridique, RH…).",
      permissions: %w[company_library],
      always_on: false,
      default_price_cents: 1500
    }
    # medical / legal / beauty / … slot in here as they're built. Adding one
    # must not require touching the core.
  }.freeze

  KEYS = CATALOG.keys.freeze
  OPTIONAL_KEYS = CATALOG.reject { |_, m| m[:always_on] }.keys.freeze

  # Modules enabled for a brand-new company. Fitness + HR + library are on by
  # default so the existing product is unchanged; an admin trims the set per
  # company from the admin console afterwards.
  DEFAULT_ENABLED = %w[core fitness hr library].freeze

  def self.exists?(key)
    CATALOG.key?(key.to_s)
  end

  def self.always_on?(key)
    CATALOG.dig(key.to_s, :always_on) || false
  end

  def self.default_price_cents(key)
    CATALOG.dig(key.to_s, :default_price_cents) || 0
  end

  # Every permission contributed by the given set of enabled module keys.
  def self.permissions_for(enabled_keys)
    keys = enabled_keys.map(&:to_s) | [ CORE_KEY ]
    keys.flat_map { |k| CATALOG.dig(k, :permissions) || [] }.uniq
  end
end
