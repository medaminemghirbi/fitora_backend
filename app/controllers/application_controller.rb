class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def authenticate_request!
    token = request.headers["Authorization"]&.split(" ")&.last
    render_unauthorized and return if token.blank?

    claims = JwtService.decode(token)
    @current_user = User.active.find_by(id: claims[:user_id])
    @current_impersonator = User.active.find_by(id: claims[:impersonator_id]) if claims[:impersonator_id]
    render_unauthorized if @current_user.nil?
  rescue JwtService::DecodeError
    render_unauthorized
  end

  def current_user
    @current_user
  end

  # The admin who is impersonating current_user, if this is an impersonation
  # session — nil for a normal login. See JwtService.encode.
  def current_impersonator
    @current_impersonator
  end

  def render_unauthorized
    render json: { error: "Unauthorized" }, status: :unauthorized
  end

  def render_forbidden(message = "You are not allowed to perform this action")
    render json: { error: message }, status: :forbidden
  end

  def render_not_found
    render json: { error: "Resource not found" }, status: :not_found
  end

  def render_bad_request(exception)
    render json: { error: exception.message }, status: :bad_request
  end

  def render_unprocessable(exception = nil)
    record = exception&.record
    errors = record ? record.errors.full_messages : [ exception&.message ].compact
    render json: { error: errors.first || "Validation failed", errors: errors }, status: :unprocessable_entity
  end
end
