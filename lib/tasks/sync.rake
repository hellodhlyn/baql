namespace :sync do
  task all: [:environment] do
    Rake::Task["sync:students"].invoke
    Rake::Task["sync:items"].invoke
  end

  task students: [:environment] do
    puts "Syncing students data..."
    Student.sync!
  end

  task items: [:environment] do
    puts "Syncing items data..."
    Item.sync!
  end
end
