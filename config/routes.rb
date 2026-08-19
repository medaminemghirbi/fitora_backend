Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login", to: "auth#login"
      post "auth/logout", to: "auth#logout"
      get "auth/me", to: "auth#me"

      resource :company, only: [ :show, :update, :create ]

      resource :location, only: [ :show, :update ]
      resources :activities
      resources :coaches
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

      get "contract", to: "contract#show"
      get "contract/plans", to: "contract#plans"
      post "contract/upgrade-request", to: "contract#request_upgrade"

      resources :membership_plans, only: [ :index, :show, :create, :update ]
      resources :memberships, only: [ :index, :show, :create ] do
        member do
          post :renew
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

      namespace :owner do
        get "dashboard", to: "dashboard#show"
        get "revenue", to: "revenue#show"
        get "reports/export", to: "reports#export"
      end

      namespace :admin do
        resources :companies, only: [ :index, :show ] do
          member do
            patch :contract, to: "companies#update_contract"
            post :impersonate, to: "companies#impersonate"
          end
        end
        resources :payments, only: [ :index ]
      end
    end
  end
end
