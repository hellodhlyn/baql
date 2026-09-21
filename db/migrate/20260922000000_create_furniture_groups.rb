class CreateFurnitureGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :furniture_groups do |t|
      t.string "baql_id", null: false
      t.string "uid", null: false

      t.timestamps
    end
    add_index :furniture_groups, :uid, unique: true

    add_column :furnitures, :furniture_group_uid, :string
    add_index :furnitures, :furniture_group_uid
  end
end
