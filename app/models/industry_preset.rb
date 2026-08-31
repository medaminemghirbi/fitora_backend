# Signup-time convenience — NOT an architectural discriminator. Picking a
# preset SEEDS a company's configuration once: which modules are on, what the
# built-in roles are called, and a starter set of navigation label overrides.
# After that, nothing in the app reads `company.industry` (it's a display
# label only, see the migration). Adding a trade means adding an entry here —
# never a `case company.industry` anywhere.
#
# Everything a preset sets stays editable afterwards from Settings → Platform.
module IndustryPreset
  DEFAULT_KEY = "generic".freeze

  # role_labels keys are Role::SYSTEM_KEYS; nav_labels keys are the frontend
  # nav blueprint labelKeys. An empty map = keep the shipped default.
  CATALOG = {
    "fitness" => {
      label: "Salle de sport / fitness",
      modules: %w[core fitness],
      role_labels: {},
      nav_labels: {}
    },
    "medical" => {
      label: "Cabinet médical",
      modules: %w[core appointments],
      role_labels: { "manager" => "Responsable", "receptionist" => "Secrétaire", "coach" => "Praticien" },
      nav_labels: { "nav.clients" => "Patients" }
    },
    "dental" => {
      label: "Cabinet dentaire",
      modules: %w[core appointments],
      role_labels: { "manager" => "Responsable", "receptionist" => "Secrétaire", "coach" => "Praticien" },
      nav_labels: { "nav.clients" => "Patients" }
    },
    "legal" => {
      label: "Cabinet juridique",
      modules: %w[core appointments],
      role_labels: { "manager" => "Associé", "receptionist" => "Assistant·e", "coach" => "Collaborateur" },
      nav_labels: {}
    },
    "beauty" => {
      label: "Institut de beauté",
      modules: %w[core appointments],
      role_labels: { "manager" => "Gérant·e", "receptionist" => "Accueil", "coach" => "Praticien·ne" },
      nav_labels: {}
    },
    "veterinary" => {
      label: "Clinique vétérinaire",
      modules: %w[core appointments],
      role_labels: { "manager" => "Responsable", "receptionist" => "Secrétaire", "coach" => "Vétérinaire" },
      nav_labels: {}
    },
    "training" => {
      label: "Centre de formation",
      modules: %w[core appointments],
      role_labels: { "manager" => "Responsable", "receptionist" => "Secrétariat", "coach" => "Formateur" },
      nav_labels: { "nav.clients" => "Stagiaires" }
    },
    "realestate" => {
      label: "Agence immobilière",
      modules: %w[core appointments],
      role_labels: { "manager" => "Directeur d'agence", "receptionist" => "Assistant·e", "coach" => "Négociateur" },
      nav_labels: { "nav.clients" => "Contacts" }
    },
    "maintenance" => {
      label: "Maintenance / SAV",
      modules: %w[core appointments],
      role_labels: { "manager" => "Responsable", "receptionist" => "Planification", "coach" => "Technicien" },
      nav_labels: {}
    },
    "generic" => {
      label: "Autre / générique",
      modules: %w[core],
      role_labels: {},
      nav_labels: {}
    }
  }.freeze

  KEYS = CATALOG.keys.freeze

  def self.exists?(key)
    CATALOG.key?(key.to_s)
  end

  def self.fetch(key)
    CATALOG.fetch(key.to_s, CATALOG[DEFAULT_KEY])
  end

  # For the settings UI: [{ key, label }] in catalogue order.
  def self.options
    CATALOG.map { |key, meta| { key: key, label: meta[:label] } }
  end

  # Apply a preset to a company: enable its modules (disable the rest),
  # rename the matching built-in roles, merge its nav-label overrides, and
  # stamp `industry`. Called at signup and whenever the owner re-picks.
  # Takes an explicit key — never inspects company.industry.
  def self.apply(company, key)
    preset = fetch(key)
    resolved_key = exists?(key) ? key.to_s : DEFAULT_KEY

    ModuleRegistry::OPTIONAL_KEYS.each do |module_key|
      record = company.company_modules.find_or_initialize_by(key: module_key)
      record.enabled = preset[:modules].include?(module_key)
      record.save!
    end

    preset[:role_labels].each do |role_key, name|
      company.roles.find_by(key: role_key)&.update!(name: name)
    end

    if preset[:modules].include?("appointments")
      %w[manager receptionist coach].each do |role_key|
        role = company.roles.find_by(key: role_key)
        role&.update!(permissions: role.permissions | %w[appointments])
      end
      AppointmentType.seed_defaults_for(company)
    end

    company.update!(
      nav_labels: company.nav_labels.merge(preset[:nav_labels]),
      industry: resolved_key
    )
  end
end
