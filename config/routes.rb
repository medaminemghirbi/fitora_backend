Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      resource :company, only: [ :show, :update, :create ] do
        post :regenerate_mobile_key
        get :mobile_key_qr
      end
      get "branding", to: "branding#show"
      get "pairing/:mobile_auth_key", to: "pairing#show"

      resource :location, only: [ :show, :update ]
      resources :activities
      resources :coaches do
        member do
          post :login, to: "coaches#set_login"
        end
      end
      resources :sessions, only: [ :index, :show, :create, :update ] do
        member do
          post :cancel
        end
      end
      resources :bookings, only: [ :index, :show, :create ] do
        member do
          post :cancel
          post :remind
        end
      end
      resources :clients, only: [ :index, :show, :create, :update ]

      get "subscription", to: "subscription#show"

      resources :contract_types, only: [ :index, :show, :create, :update ]
      resources :contracts, only: [ :index, :show, :create, :destroy ] do
        member do
          post :renew
          post :cancel
          get :receipt
        end
      end
      resources :payments, only: [ :index, :show, :create ] do
        member do
          post :refund
        end
      end

      resources :staff, only: [ :index, :create, :update ]
      resources :attendance, only: [ :index, :create ]
      resources :recurring_schedules, only: [ :index, :create, :update ]
      resources :audit_logs, only: [ :index ]
      resources :library_folders, only: [ :index, :show, :create, :update, :destroy ]
      resources :library_documents, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          get :file
        end
      end

      namespace :owner do
        get "dashboard", to: "dashboard#show"
        get "revenue", to: "revenue#show"
        get "reports/export", to: "reports#export"
      end

      namespace :admin do
        resources :companies, only: [ :index, :show ] do
          member do
            patch :subscription, to: "companies#update_subscription"
            patch :mobile_key, to: "companies#update_mobile_key"
            post :impersonate, to: "companies#impersonate"
          end
        end
        resources :payments, only: [ :index ]
      end
    end
  end
end
