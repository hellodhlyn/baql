Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  post "/graphql", to: "graphql#execute"

  get "/images/students/:uid", to: "images#student_collection"  # DEPRECATED, REMOVE IN v1
  get "/images/students/collection/:uid", to: "images#student_collection"
  get "/images/students/standing/:uid", to: "images#student_standing"
  get "/images/items/:id", to: "images#item"
end
