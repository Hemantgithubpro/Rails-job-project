Rails.application.routes.draw do
  # Health check endpoint
  get "/up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes will be added in Phase 1
      # Product routes will be added in Phase 2
      # Cart routes will be added in Phase 3
      # Checkout and order routes will be added in Phase 4
    end
  end
end
