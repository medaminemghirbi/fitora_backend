# Base policy for records that hang off an Organization (directly or through a
# belongs_to chain). Only the owner of that organization may manage them.
class OrganizationScopedPolicy < ApplicationPolicy
  def index?
    user.owner?
  end

  def show?
    owns?
  end

  def create?
    user.owner?
  end

  def update?
    owns?
  end

  def destroy?
    owns?
  end

  private

  def owns?
    user.owner? && record_organization_id == user.organization&.id
  end

  def record_organization_id
    raise NotImplementedError
  end
end
