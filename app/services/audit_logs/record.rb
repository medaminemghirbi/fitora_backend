module AuditLogs
  class Record
    def self.call(organization:, user:, action:, auditable:, metadata: {})
      AuditLog.create!(
        organization: organization,
        user: user,
        action: action,
        auditable_type: auditable.class.name,
        auditable_id: auditable.id,
        metadata: metadata
      )
    end
  end
end
