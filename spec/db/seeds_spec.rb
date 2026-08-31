require "rails_helper"

# Guards against db/seeds.rb rotting as models change. Runs the whole seed
# file inside the example's transaction (use_transactional_fixtures), so it
# leaves nothing behind. Kept deliberately light — it asserts the seed
# produces a coherent starting point, not every individual row.
RSpec.describe "db/seeds.rb" do
  it "runs cleanly and is idempotent" do
    expect {
      silence_stream($stdout) { Rails.application.load_seed }
      silence_stream($stdout) { Rails.application.load_seed }
    }.not_to raise_error

    expect(User.find_by(email: "owner@fitora.test")).to be_present
    expect(User.find_by(email: "admin@fitora.test")&.role).to eq("admin")
    expect(Company.count).to eq(2)
    expect(Company.find_by(name: "Fitora Fitness Sousse").subscription).to be_present
    expect(StaffMember.pluck(:role).uniq).to match_array(%w[manager receptionist coach])
    expect(Session.count).to be_positive
  end

  private

  def silence_stream(stream)
    old = stream.dup
    stream.reopen(File::NULL)
    stream.sync = true
    yield
  ensure
    stream.reopen(old)
    old.close
  end
end
