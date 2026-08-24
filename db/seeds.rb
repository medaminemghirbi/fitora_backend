# Fitora seed data — business-management rebuild.
#
# Staff logins (password for all: "password123"):
#   Owner:        owner@fitora.test
#   Manager:      manager@fitora.test
#   Receptionist: receptionist@fitora.test
#   Coach:        sarah.coach@fitora.test
#   Platform admin: admin@fitora.test
#
# Clients are business records only — they never log in.
# Every company has exactly one location.

puts "Seeding owner + company..."

owner = User.find_or_create_by!(email: "owner@fitora.test") do |u|
  u.first_name = "Yassine"
  u.last_name = "Ben Salah"
  u.password = "password123"
  u.role = :owner
  u.locale = "fr"
end

company = Company.find_or_create_by!(owner: owner) do |o|
  o.name = "Fitora Fitness Sousse"
  o.description = "Fitness studio"
  o.phone = "+216 20 123 456"
  o.email = "contact@fitora-sousse.test"
  o.country = "Tunisia"
  o.city = "Sousse"
  o.address = "12 Avenue Habib Bourguiba"
  o.timezone = "Africa/Tunis"
  o.currency = "TND"
end

Subscription.find_or_create_by!(company: company) do |s|
  s.status = :active
  s.starts_at = 1.month.ago
end

puts "Seeding the company's one location..."

sousse = Location.find_or_create_by!(company: company) do |l|
  l.name = "Fitora Sousse"
  l.city = "Sousse"
  l.address = "12 Avenue Habib Bourguiba"
  l.phone = "+216 20 123 456"
  l.timezone = "Africa/Tunis"
  l.business_hours_start = "06:00"
  l.business_hours_end = "22:00"
end

puts "Seeding activities..."

gym_access = Activity.find_or_create_by!(location: sousse, name: "Gym Access") do |a|
  a.emoji = "🏋️"
  a.activity_type = :open_access
  a.duration = 60
  a.capacity = 30
  a.booking_mode = :contract_required
end

ems = Activity.find_or_create_by!(location: sousse, name: "EMS") do |a|
  a.emoji = "⚡"
  a.activity_type = :slot
  a.duration = 30
  a.capacity = 1
  a.booking_mode = :pay_per_booking
end

pilates_beginner = Activity.find_or_create_by!(location: sousse, name: "Pilates Beginner") do |a|
  a.emoji = "🧘"
  a.activity_type = :group_class
  a.duration = 60
  a.capacity = 12
end

pilates_advanced = Activity.find_or_create_by!(location: sousse, name: "Pilates Advanced") do |a|
  a.emoji = "🤸"
  a.activity_type = :group_class
  a.duration = 60
  a.capacity = 10
end

yoga = Activity.find_or_create_by!(location: sousse, name: "Yoga") do |a|
  a.emoji = "🕉️"
  a.activity_type = :group_class
  a.duration = 60
  a.capacity = 12
end

puts "Seeding coaches + staff accounts..."

sarah = Coach.find_or_create_by!(company: company, first_name: "Sarah", last_name: "Martin") do |c|
  c.email = "sarah.martin@fitora.test"
  c.phone = "+216 22 111 222"
  c.bio = "Certified Pilates and Yoga instructor with 8 years of experience."
end
CoachLocation.find_or_create_by!(coach: sarah, location: sousse)

amine = Coach.find_or_create_by!(company: company, first_name: "Amine", last_name: "Ben Ali") do |c|
  c.email = "amine.benali@fitora.test"
  c.phone = "+216 22 333 444"
  c.bio = "EMS and strength training specialist."
end
CoachLocation.find_or_create_by!(coach: amine, location: sousse)

manager_user = User.find_or_create_by!(email: "manager@fitora.test") do |u|
  u.first_name = "Khaled"
  u.last_name = "Zaidi"
  u.password = "password123"
  u.role = :staff
  u.locale = "fr"
end
manager_staff = StaffMember.find_or_create_by!(user: manager_user) do |s|
  s.company = company
  s.role = :manager
end
StaffMemberLocation.find_or_create_by!(staff_member: manager_staff, location: sousse)

receptionist_user = User.find_or_create_by!(email: "receptionist@fitora.test") do |u|
  u.first_name = "Ines"
  u.last_name = "Hammami"
  u.password = "password123"
  u.role = :staff
  u.locale = "fr"
end
receptionist_staff = StaffMember.find_or_create_by!(user: receptionist_user) do |s|
  s.company = company
  s.role = :receptionist
end
StaffMemberLocation.find_or_create_by!(staff_member: receptionist_staff, location: sousse)

sarah_user = User.find_or_create_by!(email: "sarah.coach@fitora.test") do |u|
  u.first_name = "Sarah"
  u.last_name = "Martin"
  u.password = "password123"
  u.role = :staff
  u.locale = "fr"
end
sarah_staff = StaffMember.find_or_create_by!(user: sarah_user) do |s|
  s.company = company
  s.role = :coach
  s.coach = sarah
end
StaffMemberLocation.find_or_create_by!(staff_member: sarah_staff, location: sousse)

puts "Seeding sessions + recurring schedule..."

def next_occurrence(days_ahead:, hour:, minute: 0)
  Time.current.change(hour: hour, min: minute) + days_ahead.days
end

# Only pay_per_booking activities (EMS here) need an explicit session price —
# everything else is either free or gated by a contract, where the
# per-session price is irrelevant and defaults to 0.
sessions_data = [
  { activity: gym_access, coach: nil, days_ahead: 0, hour: 8 },
  { activity: ems, coach: amine, days_ahead: 0, hour: 18, price: 40 },
  { activity: pilates_beginner, coach: sarah, days_ahead: 0, hour: 18, minute: 30 },
  { activity: pilates_beginner, coach: sarah, days_ahead: 1, hour: 18, minute: 30 },
  { activity: ems, coach: amine, days_ahead: 1, hour: 17, price: 40 },
  { activity: pilates_advanced, coach: sarah, days_ahead: 2, hour: 19 },
  { activity: yoga, coach: sarah, days_ahead: 2, hour: 9 },
  { activity: yoga, coach: sarah, days_ahead: 3, hour: 9 },
  { activity: gym_access, coach: nil, days_ahead: 4, hour: 8 }
]

sessions_data.each do |data|
  starts_at = next_occurrence(days_ahead: data[:days_ahead], hour: data[:hour], minute: data[:minute] || 0)

  Session.find_or_create_by!(
    activity: data[:activity], location: sousse, coach: data[:coach], starts_at: starts_at
  ) do |s|
    s.ends_at = starts_at + data[:activity].duration.minutes
    s.capacity = data[:activity].capacity
    s.price = data[:price] || 0
    s.status = :scheduled
  end
end

pilates_recurring = RecurringSchedule.find_or_create_by!(
  activity: pilates_beginner, location: sousse, coach: sarah, company: company
) do |rs|
  rs.weekdays = [ 1, 3 ] # Monday & Wednesday
  rs.start_time = "18:30"
  rs.recurrence_type = :weekly
  rs.starts_on = Date.current
  rs.ends_on = 60.days.from_now.to_date
  rs.active = true
end
RecurringSchedules::Generate.call(schedule: pilates_recurring)

puts "Seeding contract plans..."

premium_plan = ContractType.find_or_create_by!(company: company, name: "Premium") do |p|
  p.description = "Unlimited access to gym, Pilates, EMS and Yoga."
  p.price = 89
  p.currency = company.currency
  p.billing_period = :monthly
  p.unlimited_bookings = true
  p.priority_booking = true
end

basic_plan = ContractType.find_or_create_by!(company: company, name: "Basic") do |p|
  p.description = "Gym access only, up to 8 bookings a month."
  p.price = 49
  p.currency = company.currency
  p.billing_period = :monthly
  p.unlimited_bookings = false
  p.booking_limit = 8
end
basic_plan.activity_ids = [ gym_access.id ] if basic_plan.activities.empty?

# Replaces the old Package/ClientPackage credits system: a plan can now cap
# total sessions directly via session_count ("nombre de séances") instead of
# needing a separate package purchase.
ems_plan = ContractType.find_or_create_by!(company: company, name: "EMS Pass") do |p|
  p.description = "10 EMS sessions, valid 60 days."
  p.price = 300
  p.currency = company.currency
  p.billing_period = :quarterly
  p.unlimited_bookings = false
  p.booking_limit = 10
  p.session_count = 10
end
ems_plan.activity_ids = [ ems.id ] if ems_plan.activities.empty?

puts "Seeding clients..."

clients_data = [
  { first_name: "Sami", last_name: "Trabelsi", email: "sami@example.test", phone: "+216 20 111 111" },
  { first_name: "Leila", last_name: "Gharbi", email: "leila@example.test", phone: "+216 20 222 222" },
  { first_name: "Karim", last_name: "Jendoubi", email: nil, phone: "+216 20 333 333" },
  { first_name: "Nadia", last_name: "Cherni", email: "nadia@example.test", phone: "+216 20 444 444" },
  { first_name: "Walid", last_name: "Sassi", email: nil, phone: "+216 20 555 555" },
  { first_name: "Mouna", last_name: "Ayari", email: "mouna@example.test", phone: "+216 20 666 666" }
]

clients = clients_data.map do |data|
  Client.find_or_create_by!(company: company, phone: data[:phone]) do |c|
    c.first_name = data[:first_name]
    c.last_name = data[:last_name]
    c.email = data[:email]
    c.joined_at = rand(5..120).days.ago
  end
end
sami, leila, karim, nadia, walid, mouna = clients

# Sami: active Premium contract, paid in full.
if sami.contracts.none?
  Contracts::Create.call(
    client: sami, contract_type: premium_plan, created_by: manager_user,
    starts_on: 5.days.ago.to_date, payment_method: :card, payment_amount: premium_plan.price
  )
end

# Leila: active Basic contract, only partially paid.
if leila.contracts.none?
  Contracts::Create.call(
    client: leila, contract_type: basic_plan, created_by: receptionist_user,
    starts_on: 10.days.ago.to_date, payment_method: :cash, payment_amount: 20
  )
end

# Nadia: Premium contract expiring in 3 days (shows up on the dashboard's
# "contracts expiring" widget).
if nadia.contracts.none?
  result = Contracts::Create.call(
    client: nadia, contract_type: premium_plan, created_by: manager_user,
    starts_on: 27.days.ago.to_date, payment_method: :card, payment_amount: premium_plan.price
  )
  result.contract.current_period.update!(expires_at: 3.days.from_now)
end

# Mouna: EMS Pass contract with remaining session credits.
if mouna.contracts.none?
  Contracts::Create.call(
    client: mouna, contract_type: ems_plan, created_by: owner,
    starts_on: 2.days.ago.to_date, payment_method: :cash, payment_amount: ems_plan.price
  )
end

puts "Seeding bookings + attendance..."

# The "days_ahead: 0" sessions may already be in the past by the time seeds
# run later in the day, so pick sessions guaranteed to still be bookable
# regardless of time-of-day.
upcoming_pilates_session = Session.where(activity: pilates_beginner, location: sousse, coach: sarah).where("starts_at > ?", Time.current).order(:starts_at).first
upcoming_yoga_session = Session.where(activity: yoga, location: sousse).where("starts_at > ?", Time.current).order(:starts_at).first

if upcoming_pilates_session && Booking.where(session: upcoming_pilates_session, client: sami).none?
  result = Bookings::Create.call(client: sami, session: upcoming_pilates_session)
  Attendance::Mark.call(booking: result.booking, status: :present, marked_by: sarah_user) if result.success?
end

Bookings::Create.call(client: leila, session: upcoming_yoga_session) if upcoming_yoga_session && Booking.where(session: upcoming_yoga_session, client: leila).none?
Bookings::Create.call(client: karim, session: upcoming_pilates_session) if upcoming_pilates_session && Booking.where(session: upcoming_pilates_session, client: karim).none?

puts "Seeding company library folders + documents..."

require "base64"

# A real (if tiny) PNG so Active Storage's content-type sniffing accepts it
# the same way it would a real upload — same trick as the request specs.
seed_png = Base64.decode64("iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=")

insurance_folder = LibraryFolder.find_or_create_by!(company: company, name: "Assurances") { |f| f.created_by = owner }
legal_folder = LibraryFolder.find_or_create_by!(company: company, name: "Juridique") { |f| f.created_by = owner }
hr_folder = LibraryFolder.find_or_create_by!(company: company, name: "Ressources humaines") { |f| f.created_by = owner }

{
  insurance_folder => [
    { title: "Assurance responsabilité civile", reference_number: "RC-2026-0417", issued_on: 6.months.ago.to_date, expires_on: 20.days.from_now.to_date }
  ],
  legal_folder => [
    { title: "Registre de commerce", reference_number: "RC-TU-884213", issued_on: 3.years.ago.to_date, expires_on: nil }
  ],
  hr_folder => [
    { title: "Règlement intérieur", reference_number: nil, issued_on: 1.year.ago.to_date, expires_on: nil }
  ]
}.each do |folder, docs|
  docs.each do |attrs|
    next if folder.library_documents.exists?(title: attrs[:title])

    folder.library_documents.create!(
      company: company,
      created_by: owner,
      title: attrs[:title],
      reference_number: attrs[:reference_number],
      issued_on: attrs[:issued_on],
      expires_on: attrs[:expires_on]
    ) { |d| d.file.attach(io: StringIO.new(seed_png), filename: "#{attrs[:title].parameterize}.png", content_type: "image/png") }
  end
end

puts "Seeding admin account + a second company (for the platform admin panel)..."

User.find_or_create_by!(email: "admin@fitora.test") do |u|
  u.first_name = "Fitora"
  u.last_name = "Admin"
  u.password = "password123"
  u.role = :admin
  u.locale = "fr"
end

second_owner = User.find_or_create_by!(email: "owner2@fitora.test") do |u|
  u.first_name = "Nadia"
  u.last_name = "Cherni"
  u.password = "password123"
  u.role = :owner
  u.locale = "fr"
end

second_company = Company.find_or_create_by!(owner: second_owner) do |o|
  o.name = "Zen Yoga Monastir"
  o.description = "Boutique yoga studio"
  o.city = "Monastir"
  o.country = "Tunisia"
  o.timezone = "Africa/Tunis"
  o.currency = "TND"
end

Subscription.find_or_create_by!(company: second_company) do |s|
  s.status = :active
  s.starts_at = 1.week.ago
end

Location.find_or_create_by!(company: second_company) do |l|
  l.name = "Zen Yoga Monastir"
  l.city = "Monastir"
  l.timezone = "Africa/Tunis"
end

puts "Seed complete."
puts "Owner login:        owner@fitora.test / password123"
puts "Manager login:      manager@fitora.test / password123"
puts "Receptionist login: receptionist@fitora.test / password123"
puts "Coach login:        sarah.coach@fitora.test / password123"
puts "Platform admin:     admin@fitora.test / password123"
puts "Second owner:       owner2@fitora.test / password123 (Zen Yoga Monastir)"
