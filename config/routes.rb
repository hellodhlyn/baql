Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "/graphql", to: "graphql#execute"

  get "/images/students/:id", to: "images#student"
  get "/images/items/:id", to: "images#item"
end
