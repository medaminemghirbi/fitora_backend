module AuthHelper
  def auth_headers(user)
    { "Authorization" => "Bearer #{JwtService.encode(user.id)}" }
  end
end

RSpec.configure do |config|
  config.include AuthHelper, type: :request
end
