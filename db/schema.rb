# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_09_19_130000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"

  create_table "activities", force: :cascade do |t|
    t.bigint "location_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "activity_type", default: 0, null: false
    t.integer "duration", null: false
    t.integer "capacity", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "booking_mode", default: 0, null: false
    t.string "emoji"
    t.index ["location_id"], name: "index_activities_on_location_id"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "checked_in_at"
    t.datetime "checked_out_at"
    t.bigint "marked_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_attendance_records_on_booking_id", unique: true
    t.index ["marked_by_id"], name: "index_attendance_records_on_marked_by_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "user_id"
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.bigint "auditable_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["organization_id", "created_at"], name: "index_audit_logs_on_organization_id_and_created_at"
    t.index ["organization_id"], name: "index_audit_logs_on_organization_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bookings", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "session_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "TND", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "membership_id"
    t.bigint "client_package_id"
    t.integer "payment_status", default: 0, null: false
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["client_package_id"], name: "index_bookings_on_client_package_id"
    t.index ["membership_id"], name: "index_bookings_on_membership_id"
    t.index ["session_id", "client_id"], name: "index_bookings_on_session_id_and_client_id_when_held", unique: true, where: "(status = 0)"
    t.index ["session_id"], name: "index_bookings_on_session_id"
  end

  create_table "client_packages", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "package_id", null: false
    t.integer "remaining_credits", default: 0, null: false
    t.datetime "purchased_at"
    t.datetime "expires_at"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id", "status"], name: "index_client_packages_on_client_id_and_status"
    t.index ["client_id"], name: "index_client_packages_on_client_id"
    t.index ["package_id"], name: "index_client_packages_on_package_id"
  end

  create_table "clients", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.date "date_of_birth"
    t.string "gender"
    t.string "address"
    t.string "emergency_contact_name"
    t.string "emergency_contact_phone"
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.datetime "joined_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "first_name", "last_name"], name: "index_clients_on_organization_id_and_first_name_and_last_name"
    t.index ["organization_id"], name: "index_clients_on_organization_id"
  end

  create_table "coach_locations", force: :cascade do |t|
    t.bigint "coach_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id", "location_id"], name: "index_coach_locations_on_coach_id_and_location_id", unique: true
    t.index ["coach_id"], name: "index_coach_locations_on_coach_id"
    t.index ["location_id"], name: "index_coach_locations_on_location_id"
  end

  create_table "coaches", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.text "bio"
    t.string "photo_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_coaches_on_organization_id"
  end

  create_table "locations", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "phone"
    t.string "email"
    t.string "address"
    t.string "city"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "timezone", default: "Africa/Tunis", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "business_hours_start", default: "2000-01-01 06:00:00", null: false
    t.time "business_hours_end", default: "2000-01-01 22:00:00", null: false
    t.index ["organization_id"], name: "index_locations_on_organization_id"
  end

  create_table "membership_plan_activities", force: :cascade do |t|
    t.bigint "membership_plan_id", null: false
    t.bigint "activity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_membership_plan_activities_on_activity_id"
    t.index ["membership_plan_id", "activity_id"], name: "index_plan_activities_unique", unique: true
    t.index ["membership_plan_id"], name: "index_membership_plan_activities_on_membership_plan_id"
  end

  create_table "membership_plan_locations", force: :cascade do |t|
    t.bigint "membership_plan_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_membership_plan_locations_on_location_id"
    t.index ["membership_plan_id", "location_id"], name: "index_plan_locations_unique", unique: true
    t.index ["membership_plan_id"], name: "index_membership_plan_locations_on_membership_plan_id"
  end

  create_table "membership_plans", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "TND", null: false
    t.integer "duration_days", default: 30, null: false
    t.boolean "unlimited_bookings", default: false, null: false
    t.integer "booking_limit"
    t.boolean "priority_booking", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_membership_plans_on_organization_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "membership_plan_id", null: false
    t.bigint "organization_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "starts_at"
    t.datetime "expires_at"
    t.integer "remaining_bookings"
    t.boolean "auto_renew", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "final_price", precision: 10, scale: 2
    t.integer "payment_status", default: 0, null: false
    t.bigint "created_by_id"
    t.index ["client_id", "status"], name: "index_memberships_on_client_id_and_status"
    t.index ["client_id"], name: "index_memberships_on_client_id"
    t.index ["created_by_id"], name: "index_memberships_on_created_by_id"
    t.index ["membership_plan_id"], name: "index_memberships_on_membership_plan_id"
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.bigint "owner_id", null: false
    t.string "name", null: false
    t.text "description"
    t.string "phone"
    t.string "email"
    t.string "country"
    t.string "city"
    t.decimal "latitude", precision: 10, scale: 6
    t.decimal "longitude", precision: 10, scale: 6
    t.string "address"
    t.string "timezone", default: "Africa/Tunis", null: false
    t.string "currency", default: "TND", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["owner_id"], name: "index_organizations_on_owner_id", unique: true
  end

  create_table "packages", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "activity_id"
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "TND", null: false
    t.integer "credits", null: false
    t.integer "validity_days", default: 60, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_packages_on_activity_id"
    t.index ["organization_id"], name: "index_packages_on_organization_id"
  end

  create_table "payments", force: :cascade do |t|
    t.bigint "client_id", null: false
    t.bigint "organization_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "TND", null: false
    t.integer "status", default: 0, null: false
    t.datetime "paid_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "membership_id"
    t.bigint "booking_id"
    t.integer "payment_method", default: 0, null: false
    t.text "notes"
    t.bigint "created_by_id"
    t.bigint "client_package_id"
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["client_id"], name: "index_payments_on_client_id"
    t.index ["client_package_id"], name: "index_payments_on_client_package_id"
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
    t.index ["membership_id"], name: "index_payments_on_membership_id"
    t.index ["organization_id"], name: "index_payments_on_organization_id"
  end

  create_table "recurring_schedules", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "location_id", null: false
    t.bigint "coach_id"
    t.bigint "organization_id", null: false
    t.integer "weekdays", default: [], null: false, array: true
    t.time "start_time", null: false
    t.integer "recurrence_type", default: 0, null: false
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_recurring_schedules_on_activity_id"
    t.index ["coach_id"], name: "index_recurring_schedules_on_coach_id"
    t.index ["location_id"], name: "index_recurring_schedules_on_location_id"
    t.index ["organization_id"], name: "index_recurring_schedules_on_organization_id"
    t.index ["weekdays"], name: "index_recurring_schedules_on_weekdays", using: :gin
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "activity_id", null: false
    t.bigint "location_id", null: false
    t.bigint "coach_id"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "capacity", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "recurring_schedule_id"
    t.index ["activity_id"], name: "index_sessions_on_activity_id"
    t.index ["coach_id"], name: "index_sessions_on_coach_id"
    t.index ["location_id"], name: "index_sessions_on_location_id"
    t.index ["recurring_schedule_id"], name: "index_sessions_on_recurring_schedule_id"
    t.index ["starts_at"], name: "index_sessions_on_starts_at"
    t.exclusion_constraint "coach_id WITH =, tsrange(starts_at, ends_at) WITH &&", where: "(status = 0) AND (coach_id IS NOT NULL)", using: :gist, name: "no_overlapping_coach_sessions"
  end

  create_table "staff_member_locations", force: :cascade do |t|
    t.bigint "staff_member_id", null: false
    t.bigint "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_staff_member_locations_on_location_id"
    t.index ["staff_member_id", "location_id"], name: "index_staff_member_locations_unique", unique: true
    t.index ["staff_member_id"], name: "index_staff_member_locations_on_staff_member_id"
  end

  create_table "staff_members", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "coach_id"
    t.integer "role", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id"], name: "index_staff_members_on_coach_id"
    t.index ["organization_id"], name: "index_staff_members_on_organization_id"
    t.index ["user_id"], name: "index_staff_members_on_user_id", unique: true
  end

  create_table "subscription_plans", force: :cascade do |t|
    t.string "name", null: false
    t.string "code", null: false
    t.integer "max_locations"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "billing_period", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_clients"
    t.integer "max_staff"
    t.index ["code"], name: "index_subscription_plans_on_code", unique: true
  end

  create_table "subscription_upgrade_requests", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "subscription_plan_id", null: false
    t.bigint "requested_by_id", null: false
    t.integer "payment_method", null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_subscription_upgrade_requests_on_organization_id"
    t.index ["requested_by_id"], name: "index_subscription_upgrade_requests_on_requested_by_id"
    t.index ["subscription_plan_id"], name: "index_subscription_upgrade_requests_on_subscription_plan_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "subscription_plan_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "starts_at", null: false
    t.datetime "expires_at"
    t.boolean "auto_renew", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_subscriptions_on_organization_id", unique: true
    t.index ["subscription_plan_id"], name: "index_subscriptions_on_subscription_plan_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email", null: false
    t.string "phone"
    t.string "password_digest", null: false
    t.integer "role", default: 1, null: false
    t.string "locale", default: "fr", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "activities", "locations"
  add_foreign_key "attendance_records", "bookings"
  add_foreign_key "attendance_records", "users", column: "marked_by_id"
  add_foreign_key "audit_logs", "organizations"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "bookings", "client_packages"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "memberships"
  add_foreign_key "bookings", "sessions"
  add_foreign_key "client_packages", "clients"
  add_foreign_key "client_packages", "packages"
  add_foreign_key "clients", "organizations"
  add_foreign_key "coach_locations", "coaches"
  add_foreign_key "coach_locations", "locations"
  add_foreign_key "coaches", "organizations"
  add_foreign_key "locations", "organizations"
  add_foreign_key "membership_plan_activities", "activities"
  add_foreign_key "membership_plan_activities", "membership_plans"
  add_foreign_key "membership_plan_locations", "locations"
  add_foreign_key "membership_plan_locations", "membership_plans"
  add_foreign_key "membership_plans", "organizations"
  add_foreign_key "memberships", "clients"
  add_foreign_key "memberships", "membership_plans"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users", column: "created_by_id"
  add_foreign_key "organizations", "users", column: "owner_id"
  add_foreign_key "packages", "activities"
  add_foreign_key "packages", "organizations"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "client_packages"
  add_foreign_key "payments", "clients"
  add_foreign_key "payments", "memberships"
  add_foreign_key "payments", "organizations"
  add_foreign_key "payments", "users", column: "created_by_id"
  add_foreign_key "recurring_schedules", "activities"
  add_foreign_key "recurring_schedules", "coaches"
  add_foreign_key "recurring_schedules", "locations"
  add_foreign_key "recurring_schedules", "organizations"
  add_foreign_key "sessions", "activities"
  add_foreign_key "sessions", "coaches"
  add_foreign_key "sessions", "locations"
  add_foreign_key "sessions", "recurring_schedules"
  add_foreign_key "staff_member_locations", "locations"
  add_foreign_key "staff_member_locations", "staff_members"
  add_foreign_key "staff_members", "coaches"
  add_foreign_key "staff_members", "organizations"
  add_foreign_key "staff_members", "users"
  add_foreign_key "subscription_upgrade_requests", "organizations"
  add_foreign_key "subscription_upgrade_requests", "subscription_plans"
  add_foreign_key "subscription_upgrade_requests", "users", column: "requested_by_id"
  add_foreign_key "subscriptions", "organizations"
  add_foreign_key "subscriptions", "subscription_plans"
end
