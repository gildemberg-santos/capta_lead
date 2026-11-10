Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "dashboard#index"

  get "dashboard", to: "dashboard#index"

  resources :companies do
    resources :field_sets, except: %i[index show]
  end
  resources :leads do
    member do
      post :qualify
      post :requalify
    end
  end
  resources :lead_qualifications, only: [ :index, :show ]
end
