Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "/graphql", to: "graphql#execute"

  get "/images/students/:id", to: "images#student_collection"  # DEPRECATED
  get "/images/students/collection/:id", to: "images#student_collection"
  get "/images/students/standing/:id", to: "images#student_standing"
  get "/images/items/:id", to: "images#item"
end
