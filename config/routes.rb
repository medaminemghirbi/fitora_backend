require "sidekiq/web"
require "sidekiq/cron/web"

Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # The Sidekiq dashboard. Dev-only here — in production it must sit behind
  # real authentication (basic auth / an admin session) before being exposed.
  mount Sidekiq::Web => "/sidekiq" if Rails.env.development?

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"
      get "me/permissions", to: "auth#permissions"
      get "bootstrap", to: "bootstrap#show"

      resources :notifications, only: [ :index, :show ] do
        member { patch :read }
        collection do
          post :read_all
          get :unread_count
        end
      end

      resource :company, only: [ :show, :update, :create ] do
        post :regenerate_mobile_key
        get :mobile_key_qr
        patch :industry, to: "companies#update_industry"
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

      resources :staff, only: [ :index, :show, :create, :update ]

      # RH — employment contracts + leave (foundation for the pré-fiche de paie)
      resources :work_contract_types, only: [ :index, :create, :update, :destroy ]
      resources :absence_types, only: [ :index, :create, :update, :destroy ]
      resources :work_contracts, only: [ :index, :show, :create, :update, :destroy ]
      resources :leave_requests, only: [ :index, :create, :update, :destroy ]

      # Generic appointments module (opt-in per company)
      resources :appointment_types, only: [ :index, :create, :update, :destroy ]
      resources :appointments, only: [ :index, :show, :create, :update, :destroy ] do
        member { post :cancel }
      end

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
        get "payroll", to: "payroll#index"
        get "payroll/export", to: "payroll#export"
      end

      namespace :admin do
        resources :companies, only: [ :index, :show ] do
          member do
            patch :subscription, to: "companies#update_subscription"
            patch :modules, to: "companies#update_modules"
            patch :settings, to: "companies#update_settings"
            patch :mobile_key, to: "companies#update_mobile_key"
            post :impersonate, to: "companies#impersonate"
          end
        end
        resources :modules, only: [ :index, :update ], param: :key
      end
    end
  end
end
