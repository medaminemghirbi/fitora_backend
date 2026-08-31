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

ActiveRecord::Schema[8.0].define(version: 2026_08_31_150000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gist"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pgcrypto"

  create_table "absence_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.boolean "paid", default: false, null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "abbreviation"], name: "index_absence_types_on_company_id_and_abbreviation", unique: true
    t.index ["company_id"], name: "index_absence_types_on_company_id"
  end

  create_table "active_storage_attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.uuid "record_id", null: false
    t.uuid "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "location_id", null: false
    t.string "name", null: false
    t.text "description"
    t.integer "activity_type", default: 0, null: false
    t.integer "duration", null: false
    t.integer "capacity", default: 1, null: false
    t.boolean "active", default: true, null: false
    t.integer "booking_mode", default: 0, null: false
    t.string "emoji"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_activities_on_location_id"
  end

  create_table "attendance_records", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "booking_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "checked_in_at"
    t.datetime "checked_out_at"
    t.uuid "marked_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_attendance_records_on_booking_id", unique: true
    t.index ["marked_by_id"], name: "index_attendance_records_on_marked_by_id"
  end

  create_table "audit_logs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "user_id"
    t.string "action", null: false
    t.string "auditable_type", null: false
    t.uuid "auditable_id", null: false
    t.jsonb "metadata", default: {}, null: false
    t.datetime "created_at", null: false
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["company_id", "created_at"], name: "index_audit_logs_on_company_id_and_created_at"
    t.index ["company_id"], name: "index_audit_logs_on_company_id"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "bookings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.uuid "session_id", null: false
    t.integer "status", default: 0, null: false
    t.decimal "amount", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "TND", null: false
    t.uuid "contract_period_id"
    t.integer "payment_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_bookings_on_client_id"
    t.index ["contract_period_id"], name: "index_bookings_on_contract_period_id"
    t.index ["session_id", "client_id"], name: "index_bookings_on_session_id_and_client_id_when_held", unique: true, where: "(status = 0)"
    t.index ["session_id"], name: "index_bookings_on_session_id"
  end

  create_table "clients", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
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
    t.string "password_digest"
    t.index ["company_id", "first_name", "last_name"], name: "index_clients_on_company_id_and_first_name_and_last_name"
    t.index ["company_id"], name: "index_clients_on_company_id"
  end

  create_table "coach_locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "coach_id", null: false
    t.uuid "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["coach_id", "location_id"], name: "index_coach_locations_on_coach_id_and_location_id", unique: true
    t.index ["coach_id"], name: "index_coach_locations_on_coach_id"
    t.index ["location_id"], name: "index_coach_locations_on_location_id"
  end

  create_table "coaches", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.string "email"
    t.string "phone"
    t.text "bio"
    t.string "photo_url"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_coaches_on_company_id"
  end

  create_table "companies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "owner_id", null: false
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
    t.string "slug"
    t.string "primary_color"
    t.string "mobile_auth_key", null: false
    t.integer "working_days", default: [1, 2, 3, 4, 5], null: false, array: true
    t.jsonb "nav_labels", default: {}, null: false
    t.string "industry"
    t.index ["mobile_auth_key"], name: "index_companies_on_mobile_auth_key", unique: true
    t.index ["owner_id"], name: "index_companies_on_owner_id", unique: true
    t.index ["slug"], name: "index_companies_on_slug", unique: true
  end

  create_table "company_modules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "key", null: false
    t.boolean "enabled", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "key"], name: "index_company_modules_on_company_id_and_key", unique: true
    t.index ["company_id"], name: "index_company_modules_on_company_id"
  end

  create_table "contract_periods", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "contract_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "starts_at"
    t.datetime "expires_at"
    t.integer "remaining_bookings"
    t.decimal "discount", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "final_price", precision: 10, scale: 2
    t.integer "payment_status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_id", "status"], name: "index_contract_periods_on_contract_id_and_status"
    t.index ["contract_id"], name: "index_contract_periods_on_contract_id"
  end

  create_table "contract_type_activities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "contract_type_id", null: false
    t.uuid "activity_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_contract_type_activities_on_activity_id"
    t.index ["contract_type_id", "activity_id"], name: "index_plan_activities_unique", unique: true
    t.index ["contract_type_id"], name: "index_contract_type_activities_on_contract_type_id"
  end

  create_table "contract_type_locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "contract_type_id", null: false
    t.uuid "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contract_type_id", "location_id"], name: "index_plan_locations_unique", unique: true
    t.index ["contract_type_id"], name: "index_contract_type_locations_on_contract_type_id"
    t.index ["location_id"], name: "index_contract_type_locations_on_location_id"
  end

  create_table "contract_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.string "currency", default: "TND", null: false
    t.integer "billing_period", default: 0, null: false
    t.integer "session_count"
    t.boolean "unlimited_bookings", default: false, null: false
    t.integer "booking_limit"
    t.boolean "priority_booking", default: false, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "color", default: "#4f46e5", null: false
    t.index ["company_id"], name: "index_contract_types_on_company_id"
  end

  create_table "contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.uuid "contract_type_id", null: false
    t.uuid "company_id", null: false
    t.uuid "created_by_id"
    t.boolean "auto_renew", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["client_id"], name: "index_contracts_on_client_id"
    t.index ["company_id"], name: "index_contracts_on_company_id"
    t.index ["contract_type_id"], name: "index_contracts_on_contract_type_id"
    t.index ["created_by_id"], name: "index_contracts_on_created_by_id"
  end

  create_table "leave_requests", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "staff_member_id", null: false
    t.uuid "recorded_by_id"
    t.date "starts_on", null: false
    t.date "ends_on", null: false
    t.decimal "days_count", precision: 5, scale: 1, default: "0.0", null: false
    t.integer "status", default: 1, null: false
    t.string "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "absence_type_id", null: false
    t.index ["absence_type_id"], name: "index_leave_requests_on_absence_type_id"
    t.index ["company_id"], name: "index_leave_requests_on_company_id"
    t.index ["recorded_by_id"], name: "index_leave_requests_on_recorded_by_id"
    t.index ["staff_member_id", "starts_on"], name: "index_leave_requests_on_staff_member_id_and_starts_on"
    t.index ["staff_member_id"], name: "index_leave_requests_on_staff_member_id"
  end

  create_table "library_documents", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "folder_id", null: false
    t.uuid "company_id", null: false
    t.uuid "created_by_id"
    t.string "title", null: false
    t.string "reference_number"
    t.date "issued_on"
    t.date "expires_on"
    t.text "notes"
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "expires_on"], name: "index_library_documents_on_company_id_and_expires_on"
    t.index ["company_id"], name: "index_library_documents_on_company_id"
    t.index ["created_by_id"], name: "index_library_documents_on_created_by_id"
    t.index ["folder_id"], name: "index_library_documents_on_folder_id"
  end

  create_table "library_folders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "created_by_id"
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "name"], name: "index_library_folders_on_company_id_and_name", unique: true
    t.index ["company_id"], name: "index_library_folders_on_company_id"
    t.index ["created_by_id"], name: "index_library_folders_on_created_by_id"
  end

  create_table "locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
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
    t.time "business_hours_start", default: "2000-01-01 06:00:00", null: false
    t.time "business_hours_end", default: "2000-01-01 22:00:00", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_locations_on_company_id"
  end

  create_table "payments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "client_id", null: false
    t.uuid "company_id", null: false
    t.decimal "amount", precision: 10, scale: 2, null: false
    t.string "currency", default: "TND", null: false
    t.integer "status", default: 0, null: false
    t.datetime "paid_at"
    t.uuid "contract_period_id"
    t.uuid "booking_id"
    t.integer "payment_method", default: 0, null: false
    t.text "notes"
    t.uuid "created_by_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id"
    t.index ["client_id"], name: "index_payments_on_client_id"
    t.index ["company_id"], name: "index_payments_on_company_id"
    t.index ["contract_period_id"], name: "index_payments_on_contract_period_id"
    t.index ["created_by_id"], name: "index_payments_on_created_by_id"
  end

  create_table "recurring_schedules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "activity_id", null: false
    t.uuid "location_id", null: false
    t.uuid "coach_id"
    t.uuid "company_id", null: false
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
    t.index ["company_id"], name: "index_recurring_schedules_on_company_id"
    t.index ["location_id"], name: "index_recurring_schedules_on_location_id"
    t.index ["weekdays"], name: "index_recurring_schedules_on_weekdays", using: :gin
  end

  create_table "roles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "key", null: false
    t.string "name", null: false
    t.string "permissions", default: [], null: false, array: true
    t.boolean "builtin", default: false, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "key"], name: "index_roles_on_company_id_and_key", unique: true
    t.index ["company_id"], name: "index_roles_on_company_id"
  end

  create_table "sessions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "activity_id", null: false
    t.uuid "location_id", null: false
    t.uuid "coach_id"
    t.datetime "starts_at", null: false
    t.datetime "ends_at", null: false
    t.integer "capacity", null: false
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "status", default: 0, null: false
    t.uuid "recurring_schedule_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["activity_id"], name: "index_sessions_on_activity_id"
    t.index ["coach_id"], name: "index_sessions_on_coach_id"
    t.index ["location_id"], name: "index_sessions_on_location_id"
    t.index ["recurring_schedule_id"], name: "index_sessions_on_recurring_schedule_id"
    t.index ["starts_at"], name: "index_sessions_on_starts_at"
    t.exclusion_constraint "coach_id WITH =, tsrange(starts_at, ends_at) WITH &&", where: "(status = 0) AND (coach_id IS NOT NULL)", using: :gist, name: "no_overlapping_coach_sessions"
  end

  create_table "staff_member_locations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "staff_member_id", null: false
    t.uuid "location_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["location_id"], name: "index_staff_member_locations_on_location_id"
    t.index ["staff_member_id", "location_id"], name: "index_staff_member_locations_unique", unique: true
    t.index ["staff_member_id"], name: "index_staff_member_locations_on_staff_member_id"
  end

  create_table "staff_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "company_id", null: false
    t.uuid "coach_id"
    t.integer "role", default: 0, null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "role_id"
    t.index ["coach_id"], name: "index_staff_members_on_coach_id"
    t.index ["company_id"], name: "index_staff_members_on_company_id"
    t.index ["role_id"], name: "index_staff_members_on_role_id"
    t.index ["user_id"], name: "index_staff_members_on_user_id", unique: true
  end

  create_table "subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "starts_at", null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_subscriptions_on_company_id", unique: true
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

  create_table "work_contract_types", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.string "name", null: false
    t.string "abbreviation", null: false
    t.boolean "fixed_term", default: false, null: false
    t.boolean "active", default: true, null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id", "abbreviation"], name: "index_work_contract_types_on_company_id_and_abbreviation", unique: true
    t.index ["company_id"], name: "index_work_contract_types_on_company_id"
  end

  create_table "work_contracts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "company_id", null: false
    t.uuid "staff_member_id", null: false
    t.uuid "work_contract_type_id", null: false
    t.string "reference"
    t.string "job_title"
    t.date "starts_on", null: false
    t.date "ends_on"
    t.date "trial_period_end"
    t.decimal "weekly_hours", precision: 6, scale: 2
    t.decimal "gross_monthly_salary", precision: 12, scale: 3, default: "0.0", null: false
    t.decimal "hourly_rate", precision: 10, scale: 3
    t.string "currency", default: "TND", null: false
    t.integer "payment_method", default: 0, null: false
    t.string "bank_name"
    t.string "bank_iban"
    t.string "cnss_number"
    t.date "cnss_affiliated_on"
    t.jsonb "allowances", default: [], null: false
    t.decimal "paid_leave_days_per_year", precision: 5, scale: 1, default: "30.0", null: false
    t.integer "notice_period_days"
    t.date "terminated_on"
    t.string "termination_reason"
    t.integer "status", default: 0, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["company_id"], name: "index_work_contracts_on_company_id"
    t.index ["staff_member_id", "status"], name: "index_work_contracts_on_staff_member_id_and_status"
    t.index ["staff_member_id"], name: "index_work_contracts_on_staff_member_id"
    t.index ["work_contract_type_id"], name: "index_work_contracts_on_work_contract_type_id"
  end

  add_foreign_key "absence_types", "companies"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "activities", "locations"
  add_foreign_key "attendance_records", "bookings"
  add_foreign_key "attendance_records", "users", column: "marked_by_id"
  add_foreign_key "audit_logs", "companies"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "bookings", "clients"
  add_foreign_key "bookings", "contract_periods"
  add_foreign_key "bookings", "sessions"
  add_foreign_key "clients", "companies"
  add_foreign_key "coach_locations", "coaches"
  add_foreign_key "coach_locations", "locations"
  add_foreign_key "coaches", "companies"
  add_foreign_key "companies", "users", column: "owner_id"
  add_foreign_key "company_modules", "companies"
  add_foreign_key "contract_periods", "contracts"
  add_foreign_key "contract_type_activities", "activities"
  add_foreign_key "contract_type_activities", "contract_types"
  add_foreign_key "contract_type_locations", "contract_types"
  add_foreign_key "contract_type_locations", "locations"
  add_foreign_key "contract_types", "companies"
  add_foreign_key "contracts", "clients"
  add_foreign_key "contracts", "companies"
  add_foreign_key "contracts", "contract_types"
  add_foreign_key "contracts", "users", column: "created_by_id"
  add_foreign_key "leave_requests", "absence_types"
  add_foreign_key "leave_requests", "companies"
  add_foreign_key "leave_requests", "staff_members"
  add_foreign_key "leave_requests", "users", column: "recorded_by_id"
  add_foreign_key "library_documents", "companies"
  add_foreign_key "library_documents", "library_folders", column: "folder_id"
  add_foreign_key "library_documents", "users", column: "created_by_id"
  add_foreign_key "library_folders", "companies"
  add_foreign_key "library_folders", "users", column: "created_by_id"
  add_foreign_key "locations", "companies"
  add_foreign_key "payments", "bookings"
  add_foreign_key "payments", "clients"
  add_foreign_key "payments", "companies"
  add_foreign_key "payments", "contract_periods"
  add_foreign_key "payments", "users", column: "created_by_id"
  add_foreign_key "recurring_schedules", "activities"
  add_foreign_key "recurring_schedules", "coaches"
  add_foreign_key "recurring_schedules", "companies"
  add_foreign_key "recurring_schedules", "locations"
  add_foreign_key "roles", "companies"
  add_foreign_key "sessions", "activities"
  add_foreign_key "sessions", "coaches"
  add_foreign_key "sessions", "locations"
  add_foreign_key "sessions", "recurring_schedules"
  add_foreign_key "staff_member_locations", "locations"
  add_foreign_key "staff_member_locations", "staff_members"
  add_foreign_key "staff_members", "coaches"
  add_foreign_key "staff_members", "companies"
  add_foreign_key "staff_members", "roles"
  add_foreign_key "staff_members", "users"
  add_foreign_key "subscriptions", "companies"
  add_foreign_key "work_contract_types", "companies"
  add_foreign_key "work_contracts", "companies"
  add_foreign_key "work_contracts", "staff_members"
  add_foreign_key "work_contracts", "work_contract_types"
end
