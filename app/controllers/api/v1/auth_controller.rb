module Api
  module V1
    class AuthController < ApplicationController
      before_action :authenticate_request!, only: [ :me, :logout ]

      # POST /api/v1/auth/register — a gym signing up for Fitora. Every other
      # account (manager/receptionist/coach) is created by the owner via
      # StaffController, never self-registered.
      def register
        user = User.new(
          first_name: params[:first_name],
          last_name: params[:last_name],
          email: params[:email],
          phone: params[:phone],
          password: params[:password],
          role: :owner,
          locale: params[:locale].presence || "fr"
        )

        if user.save
          render json: { token: JwtService.encode(user.id), user: UserSerializer.new(user).as_json }, status: :created
        else
          render json: { error: user.errors.full_messages.first, errors: user.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # POST /api/v1/auth/login
      def login
        user = User.active.find_by(email: params[:email].to_s.downcase.strip)

        if user&.authenticate(params[:password])
          render json: { token: JwtService.encode(user.id), user: UserSerializer.new(user).as_json }
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      # POST /api/v1/auth/logout
      def logout
        # Stateless JWT — nothing to invalidate server-side in V0; the client discards the token.
        head :no_content
      end

      # GET /api/v1/auth/me
      def me
        render json: { user: UserSerializer.new(current_user).as_json }
      end
    end
  end
end
