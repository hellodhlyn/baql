class AddDefenseTypesToRaids < ActiveRecord::Migration[8.0]
  class LegacyRaid < ApplicationRecord
    self.table_name = "raids"
    self.inheritance_column = :_type_disabled
  end

  def change
    add_column :raids, :defense_types, :jsonb, default: []
    LegacyRaid.reset_column_information
    LegacyRaid.all.each do |raid|
      raid.update!(defense_types: [{ defense_type: raid.read_attribute(:defense_type), difficulty: nil }])
    end
  end
end
