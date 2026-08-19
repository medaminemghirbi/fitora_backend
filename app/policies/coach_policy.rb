class CoachPolicy < OrganizationScopedPolicy
  private

  def record_organization_id
    record.organization_id
  end
end
