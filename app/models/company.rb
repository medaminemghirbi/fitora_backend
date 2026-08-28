class Company < ApplicationRecord
  MOBILE_AUTH_KEY_LENGTH = 8

  belongs_to :owner, class_name: "User", inverse_of: :company

  # White-label branding — logo shown in the owner/coach shells, primary_color
  # overrides --color-primary (see BrandingService on the frontend, which
  # derives hover/soft tones from it via CSS color-mix() rather than storing
  # them separately). slug is unused today; it's reserved so hostname-based
  # tenant resolution can be added later without another migration.
  has_one_attached :logo

  has_many :locations, dependent: :destroy
  has_many :coaches, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :clients, dependent: :destroy
  has_many :contract_types, dependent: :destroy
  has_many :contracts, dependent: :destroy
  has_many :contract_periods, through: :contracts
  has_many :payments, dependent: :destroy
  has_many :staff_members, dependent: :destroy
  has_many :recurring_schedules, dependent: :destroy
  has_many :audit_logs, dependent: :destroy
  has_many :library_folders, dependent: :destroy
  has_many :library_documents, dependent: :destroy

  validates :name, presence: true
  validates :timezone, :currency, presence: true
  validates :slug, uniqueness: true, allow_nil: true,
                    format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: "must contain only lowercase letters, numbers, and hyphens" }
  validates :primary_color, format: { with: /\A#[0-9a-fA-F]{6}\z/, message: "must be a hex color like #4f46e5" }, allow_nil: true

  # Pairing secret for the mobile app (QR code + plain text, shown to the
  # owner in Settings). The owner can only regenerate it (a fresh random
  # value); only a Fitora admin can set it to a specific value by hand
  # (Api::V1::Admin::CompaniesController#update_mobile_key) — see
  # Api::V1::CompaniesController for why it's excluded from company_params.
  before_validation :assign_mobile_auth_key, on: :create

  validates :mobile_auth_key, presence: true, uniqueness: true, length: { minimum: 6, maximum: 32 },
                               format: { with: /\A[a-z0-9]+\z/, message: "must contain only lowercase letters and numbers" }

  # Every company has exactly one location — created automatically at
  # signup (see Api::V1::CompaniesController#create) and never a second
  # one. Activities, coaches, and staff all attach to it implicitly instead
  # of asking staff to pick a location that doesn't meaningfully vary.
  def location
    locations.first
  end

  def regenerate_mobile_auth_key!
    update!(mobile_auth_key: self.class.generate_mobile_auth_key)
  end

  def self.generate_mobile_auth_key
    loop do
      key = SecureRandom.alphanumeric(MOBILE_AUTH_KEY_LENGTH).downcase
      break key unless exists?(mobile_auth_key: key)
    end
  end

  private

  def assign_mobile_auth_key
    self.mobile_auth_key ||= self.class.generate_mobile_auth_key
  end
end
