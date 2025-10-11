class AddStudentFavoriteItems < ActiveRecord::Migration[8.0]
  def change
    create_table :student_favorite_items do |t|
      t.string :student_uid, null: false
      t.string :item_uid, null: false
      t.integer :exp, null: false
      t.integer :favorite_level, null: false
      t.boolean :favorited, null: false
      t.timestamps

      t.index :student_uid
      t.index :item_uid
    end
  end
end
