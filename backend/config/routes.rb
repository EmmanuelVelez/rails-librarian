Rails.application.routes.draw do
  devise_for :users,
    path: "auth",
    path_names: {
      sign_in: "login",
      sign_out: "logout",
      registration: "register"
    },
    controllers: {
      sessions: "users/sessions",
      registrations: "users/registrations"
    }

  namespace :api do
    namespace :v1 do
      resources :books, only: [:index, :show, :create, :update, :destroy]

      resources :borrowings, only: [:index, :create] do
        member do
          put :return
        end
      end

      get "dashboard", to: "dashboard#index"
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
