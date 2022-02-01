require "sidekiq/web"

Rails.application.routes.draw do
  mount Sidekiq::Web => "/sidekiq"

  resources :tasks, only: [:new, :create, :index]

  root to: "tasks#index"
end
