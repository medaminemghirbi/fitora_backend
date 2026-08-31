class CreateAppointments < ActiveRecord::Migration[8.0]
  # The generic "appointments" module: 1:1 bookings between a contact and
  # (optionally) a staff member, for domains that run an agenda rather than
  # group classes — medical, dental, beauty, legal, veterinary, repair…
  # Opt-in per company (ModuleRegistry / CompanyModule), like fitness.
  def change
    create_table :appointment_types, id: :uuid do |t|
      t.references :company, type: :uuid, null: false, foreign_key: true, index: true
      t.string :name, null: false
      t.integer :duration_minutes, null: false, default: 30
      t.string :color, null: false, default: "#4f46e5"
      t.boolean :active, null: false, default: true
      t.integer :position, null: false, default: 0
      t.timestamps
    end
    add_index :appointment_types, [ :company_id, :name ], unique: true

    create_table :appointments, id: :uuid do |t|
      t.references :company, type: :uuid, null: false, foreign_key: true, index: true
      t.references :client, type: :uuid, null: false, foreign_key: true, index: true
      t.references :staff_member, type: :uuid, foreign_key: true, index: true
      t.references :appointment_type, type: :uuid, foreign_key: true, index: true
      t.references :location, type: :uuid, foreign_key: true, index: true
      t.uuid :created_by_id
      t.datetime :starts_at, null: false
      t.datetime :ends_at, null: false
      t.integer :status, null: false, default: 0
      t.string :title
      t.text :notes
      t.timestamps
    end
    add_index :appointments, [ :company_id, :starts_at ]
    add_foreign_key :appointments, :users, column: :created_by_id
  end
end
