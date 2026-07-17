# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require_relative "config/application"

Rails.application.load_tasks

private_tasks = Rails.root.join("private", "baql-sync", "integrations", "baql", "tasks", "*.rake")
Dir.glob(private_tasks).sort.each { |path| import path }
