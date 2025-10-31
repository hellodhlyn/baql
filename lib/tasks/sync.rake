namespace :sync do
  task all: [:environment] do
    Rake::Task["sync:students"].invoke
    Rake::Task["sync:items"].invoke
    Rake::Task["sync:furnitures"].invoke
    Rake::Task["sync:equipments"].invoke
  end

  task students: [:environment] do
    puts "Syncing students data..."
    Student.sync!
  end

  task items: [:environment] do
    puts "Syncing items data..."
    Resources::Item.sync!
  end

  task furnitures: [:environment] do
    puts "Syncing furnitures data..."
    Resources::Furniture.sync!
  end

  task equipments: [:environment] do
    puts "Syncing equipments data..."
    Resources::Equipment.sync!
  end
end
