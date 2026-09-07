class ApplicationController < ActionController::API
  # Base controller for API
  # Authentication and authorization will be added in Phase 1

  rescue_from StandardError, with: :render_internal_error
  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActionController::ParameterMissing, with: :render_bad_request

  private

  def render_internal_error(exception)
    if Rails.env.production?
      render json: {
        error: {
          code: "internal_error",
          message: "An unexpected error occurred"
        }
      }, status: :internal_server_error
    else
      render json: {
        error: {
          code: "internal_error",
          message: exception.message,
          details: exception.backtrace&.first(5)
        }
      }, status: :internal_server_error
    end
  end

  def render_not_found(exception)
    render json: {
      error: {
        code: "not_found",
        message: exception.message || "Resource not found"
      }
    }, status: :not_found
  end

  def render_bad_request(exception)
    render json: {
      error: {
        code: "bad_request",
        message: exception.message
      }
    }, status: :bad_request
  end
end
