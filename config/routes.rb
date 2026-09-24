Rails.application.routes.draw do
  # Liveness checks boot; readiness also checks the database.
  get "up", to: "rails/health#show", as: :rails_health_check
  get "ready", to: "readiness#show", as: :readiness_check

  get "manifest", to: "rails/pwa#manifest", as: :pwa_manifest
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"

  # Error pages are reached through config.exceptions_app.
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable", via: :all
  match "/500", to: "errors#internal_error", via: :all

  root "books#index"

  resources :books, only: %i[index show new create edit update destroy]
end
