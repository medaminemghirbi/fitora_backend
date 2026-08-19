class JwtService
  ALGORITHM = "HS256".freeze
  EXPIRATION = 7.days

  class DecodeError < StandardError; end

  # impersonator_id is only set for an admin-initiated impersonation session
  # (see Api::V1::Admin::OrganizationsController#impersonate) — it lets
  # authenticate_request! surface who is really behind the wheel without
  # changing what current_user resolves to (still the impersonated owner, so
  # every existing owner-only guard/capability check keeps working as-is).
  def self.encode(user_id, impersonator_id: nil)
    payload = { user_id: user_id, exp: EXPIRATION.from_now.to_i }
    payload[:impersonator_id] = impersonator_id if impersonator_id
    JWT.encode(payload, secret, ALGORITHM)
  end

  def self.decode(token)
    payload = JWT.decode(token, secret, true, algorithm: ALGORITHM).first
    { user_id: payload["user_id"], impersonator_id: payload["impersonator_id"] }
  rescue JWT::DecodeError, JWT::ExpiredSignature
    raise DecodeError
  end

  def self.secret
    Rails.application.secret_key_base
  end
end
