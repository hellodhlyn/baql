class AddItemsAndRelations < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :uid, null: false
      t.string :name, null: false
      t.string :category, null: false
      t.string :sub_category
      t.integer :rarity, null: false
      t.timestamps

      t.index :uid, unique: true
    end

    create_table :student_skill_items do |t|
      t.string :student_uid, null: false
      t.string :item_uid, null: false
      t.string :skill_type, null: false
      t.integer :skill_level, null: false
      t.integer :amount, null: false
      t.timestamps

      t.index :student_uid
      t.index :item_uid
    end
  end
end
