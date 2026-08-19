class Location < ApplicationRecord
  belongs_to :organization

  has_many :activities, dependent: :destroy
  has_many :sessions, dependent: :destroy
  has_many :coach_locations, dependent: :destroy
  has_many :coaches, through: :coach_locations
  has_many :membership_plan_locations, dependent: :destroy
  has_many :membership_plans, through: :membership_plan_locations
  has_many :staff_member_locations, dependent: :destroy
  has_many :staff_members, through: :staff_member_locations

  validates :name, presence: true
  validates :timezone, presence: true

  scope :active, -> { where(active: true) }
end
