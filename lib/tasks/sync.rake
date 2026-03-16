namespace :sync do
  task all: [:environment] do
    Rake::Task["sync:students"].invoke
    Rake::Task["sync:items"].invoke
    Rake::Task["sync:furnitures"].invoke
    Rake::Task["sync:equipments"].invoke
    Rake::Task["sync:currencies"].invoke
  end

  task students: [:environment] do
    puts "Syncing students data..."
    Student.sync!
  end

  task items: [:environment] do
    puts "Syncing items data..."
    Item.sync!
    StudentFavoriteItem.sync!
  end

  task furnitures: [:environment] do
    puts "Syncing furnitures data..."
    Furniture.sync!
  end

  task equipments: [:environment] do
    puts "Syncing equipments data..."
    Equipment.sync!
  end

  task currencies: [:environment] do
    puts "Syncing currencies data..."
    Currency.sync!
  end
end
