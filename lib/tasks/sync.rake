namespace :sync do
  task all: [:environment] do
    Rake::Task["sync:events"].invoke
    Rake::Task["sync:raid_bosses"].invoke
    Rake::Task["sync:stages"].invoke
  end

  task events: [:environment] do
    puts "Syncing events data..."
    EventContent.sync!
  end

  task raid_bosses: [:environment] do
    puts "Syncing raid bosses data..."
    RaidBoss.sync!
  end

  task stages: [:environment] do
    puts "Syncing stages data..."
    GachaGroup.sync!
    Stage.sync!
  end
end
