class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :user, foreign_key: true, index: true
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.jsonb :metadata, null: false, default: {}

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [ :organization_id, :created_at ]
    add_index :audit_logs, [ :auditable_type, :auditable_id ]
  end
end
