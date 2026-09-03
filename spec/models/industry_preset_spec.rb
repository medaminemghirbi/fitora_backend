require "rails_helper"

RSpec.describe IndustryPreset do
  let(:company) { create(:company) }

  describe ".apply" do
    it "medical: core + appointments, renamed roles, Patients label, stamped industry" do
      described_class.apply(company, "medical")
      company.reload

      expect(company.enabled_module_keys).to match_array(%w[core appointments hr library])
      expect(company.appointment_types.count).to be_positive
      expect(company.roles.find_by(key: "coach").permissions).to include("appointments")
      expect(company.roles.find_by(key: "coach").name).to eq("Praticien")
      expect(company.roles.find_by(key: "receptionist").name).to eq("Secrétaire")
      expect(company.nav_labels).to include("nav.clients" => "Patients")
      expect(company.industry).to eq("medical")
    end

    it "fitness: enables the fitness module and leaves labels/roles at the defaults" do
      described_class.apply(company, "medical")   # start elsewhere
      described_class.apply(company, "fitness")
      company.reload

      expect(company.enabled_module_keys).to match_array(%w[core fitness hr library])
      expect(company.industry).to eq("fitness")
      # re-applying does not un-rename a role the new preset doesn't mention
      expect(company.roles.find_by(key: "coach").name).to eq("Praticien")
    end

    it "keeps a company's own nav label the preset doesn't touch" do
      company.update!(nav_labels: { "nav.payments" => "Encaissements" })
      described_class.apply(company, "medical")
      expect(company.reload.nav_labels).to include("nav.payments" => "Encaissements", "nav.clients" => "Patients")
    end

    it "falls back to the generic preset for an unknown key" do
      described_class.apply(company, "spaceship")
      company.reload
      expect(company.enabled_module_keys).to match_array(%w[core hr library])
      expect(company.industry).to eq("generic")
    end
  end

  it "exposes options in catalogue order" do
    expect(described_class.options.first).to eq(key: "fitness", label: "Salle de sport / fitness")
    expect(described_class.options.map { |o| o[:key] }).to include("generic")
  end
end
