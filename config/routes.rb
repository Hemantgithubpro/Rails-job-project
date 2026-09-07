Rails.application.routes.draw do
  # Health check endpoint
  get "/up" => "rails/health#show", as: :rails_health_check

  # API routes
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"

      # Product routes (public)
      resources :products, only: [:index, :show]

      # Admin routes
      namespace :admin do
        resources :products, except: [:new, :edit]
        # Cart routes will be added in Phase 3
        # Checkout and order routes will be added in Phase 4
      end
    end
  end
end
