source "https://rubygems.org"

gem "rails", "~> 8.0.5", ">= 8.0.5.1"
# Use postgresql as the database for Active Record
gem "pg", "~> 1.1"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"

# Password hashing for User#password
gem "bcrypt", "~> 3.1.7"

# JWT encode/decode for API authentication
gem "jwt"

# Cross-Origin Resource Sharing, needed for the Angular dev server
gem "rack-cors"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

# Styled .xlsx generation (colored cells) for the owner's Premium report export
gem "caxlsx"

# PDF invoice/receipt generation for the Premium membership receipt download
gem "prawn"
gem "prawn-table"
# Prawn uses Matrix internally — no longer a Ruby default gem, must be explicit
gem "matrix"

# QR code for the company mobile pairing key — generated server-side (SVG)
# so the key itself never leaves the app to a third-party QR API.
gem "rqrcode"

# Background jobs (expiry scans, notification fan-out) + the ActionCable
# Redis pub/sub backend for real-time notifications. Redis already runs
# locally; set REDIS_URL to point elsewhere.
gem "redis", "~> 6"
gem "sidekiq", "~> 7"
gem "sidekiq-cron", "~> 2"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "dotenv-rails"
end
