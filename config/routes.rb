Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  devise_for :users

  # Signed-in users land on the blog; everyone else sees the landing page.
  authenticated :user do
    root "posts#index", as: :authenticated_root
  end
  root "static#index"

  get "about", to: "static#about"
  get "contact", to: "static#contact"
  get "profile", to: "static#profile"
  get "settings", to: "static#settings"

  resources :posts do
    resources :comments, only: %i[create edit update destroy]
    member do
      put :like, to: "posts#upvote"
      put :dislike, to: "posts#downvote"
    end
  end

  resources :questions do
    resources :answers, only: %i[create destroy]
  end

  resources :activities, only: :index
  resources :conversations, only: %i[index show]
  resources :personal_messages, only: %i[new create]
  resources :users, only: %i[index show]
  resources :friendships, only: %i[create destroy]
  get "my_friends", to: "users#my_friends"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up", to: "rails/health#show", as: :rails_health_check
end
