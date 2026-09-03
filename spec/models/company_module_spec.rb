require "rails_helper"

RSpec.describe CompanyModule do
  let(:company) { create(:company) }

  it "rejects a key not in the registry" do
    expect(build(:company_module, company: company, key: "teleportation")).not_to be_valid
  end

  describe "Company#module_enabled? / #enabled_module_keys" do
    it "always reports core, plus the enabled optional modules" do
      expect(company.enabled_module_keys).to match_array(%w[core fitness hr library])
      expect(company).to be_module_enabled("core")
      expect(company).to be_module_enabled("fitness")
    end

    it "reflects a disabled module" do
      company.company_modules.find_by(key: "fitness").update!(enabled: false)
      expect(company.reload.enabled_module_keys).to match_array(%w[core hr library])
      expect(company).not_to be_module_enabled("fitness")
      expect(company).to be_module_enabled("core")
    end
  end

  describe ".sync_defaults_for" do
    it "is idempotent" do
      expect { 2.times { described_class.sync_defaults_for(company) } }
        .not_to change { company.company_modules.reload.count }
    end
  end
end
