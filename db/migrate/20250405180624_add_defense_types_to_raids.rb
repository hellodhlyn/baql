class AddDefenseTypesToRaids < ActiveRecord::Migration[8.0]
  def change
    add_column :raids, :defense_types, :jsonb, default: []
    Raid.all.each do |raid|
      raid.update!(defense_types: [{ defense_type: raid.defense_type, difficulty: nil }])
    end
  end
end
