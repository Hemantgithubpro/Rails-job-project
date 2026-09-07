module Api
  module V1
    class BaseController < ApplicationController
      before_action :authenticate_user!

      private

      def authenticate_user!
        token = extract_bearer_token
        @current_user = AuthenticationService.authenticate_token(token)

        unless @current_user
          render json: {
            error: {
              code: "unauthorized",
              message: "Invalid or missing authentication token"
            }
          }, status: :unauthorized
        end
      end

      def authenticate_admin!
        unless @current_user&.admin?
          render json: {
            error: {
              code: "forbidden",
              message: "You are not authorized to perform this action"
            }
          }, status: :forbidden
        end
      end

      def current_user
        @current_user
      end

      def extract_bearer_token
        header = request.headers["Authorization"]
        return nil unless header.present?

        pattern = /^Bearer +(.+)$/i
        header.match(pattern)&.captures&.first
      end
    end
  end
end
