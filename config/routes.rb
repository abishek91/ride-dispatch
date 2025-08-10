Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Main simulation interface
  root "simulation#index"

  # Simulation controls
  post "tick", to: "simulation#tick"
  post "reset", to: "simulation#reset"

  # Driver management
  resources :drivers, only: [ :create, :destroy ] do
    member do
      patch :update_status
    end
  end

  # Rider management
  resources :riders, only: [ :create, :destroy ]

  # Ride request management
  resources :ride_requests, only: [ :create ]

  # Driver responses to ride assignments
  post "driver_responses/:ride_request_id/accept", to: "driver_responses#accept", as: :accept_ride
  post "driver_responses/:ride_request_id/reject", to: "driver_responses#reject", as: :reject_ride
end
