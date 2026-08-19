class CoachLocation < ApplicationRecord
  belongs_to :coach
  belongs_to :location

  validates :coach_id, uniqueness: { scope: :location_id }
  validate :same_organization

  private

  def same_organization
    return if coach.blank? || location.blank?

    if coach.organization_id != location.organization_id
      errors.add(:location, "must belong to the coach's organization")
    end
  end
end
