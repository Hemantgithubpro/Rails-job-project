module Api
  module V1
    class AuthController < BaseController
      # Authentication endpoints are public
      skip_before_action :authenticate_user!, only: [:register, :login]

      def register
        result = AuthenticationService.register(
          email: register_params[:email],
          password: register_params[:password]
        )

        render json: {
          user: user_json(result[:user]),
          token: result[:token]
        }, status: :created
      rescue AuthenticationService::UserExistsError => e
        render json: {
          error: {
            code: "validation_failed",
            message: e.message
          }
        }, status: :unprocessable_entity
      end

      def login
        result = AuthenticationService.login(
          email: login_params[:email],
          password: login_params[:password]
        )

        render json: {
          user: user_json(result[:user]),
          token: result[:token]
        }, status: :ok
      rescue AuthenticationService::InvalidCredentialsError => e
        render json: {
          error: {
            code: "invalid_credentials",
            message: e.message
          }
        }, status: :unauthorized
      end

      private

      def register_params
        params.permit(:email, :password)
      end

      def login_params
        params.permit(:email, :password)
      end

      def user_json(user)
        {
          id: user.id,
          email: user.email,
          role: user.role,
          created_at: user.created_at.iso8601
        }
      end
    end
  end
end
