class Package < ApplicationRecord
  belongs_to :organization
  belongs_to :activity, optional: true

  has_many :client_packages, dependent: :restrict_with_error

  validates :name, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0 }
  validates :credits, numericality: { greater_than: 0 }
  validates :validity_days, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
end
