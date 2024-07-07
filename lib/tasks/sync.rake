namespace :sync do
  task all: [:environment] do
    Rake::Task["sync:students"].invoke
  end

  task students: [:environment] do
    puts "Syncing students data..."
    Student.sync!
  end
end
