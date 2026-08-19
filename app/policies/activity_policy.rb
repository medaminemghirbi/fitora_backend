class ActivityPolicy < OrganizationScopedPolicy
  private

  def record_organization_id
    record.location.organization_id
  end
end
