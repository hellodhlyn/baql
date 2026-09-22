class CreateFurnitureCatalog < ActiveRecord::Migration[8.1]
  def change
    create_table :furniture_themes do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.timestamps
    end
    add_index :furniture_themes, :uid, unique: true

    create_table :furniture_template_previews do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :furniture_theme_uid, null: false
      t.integer :display_order, null: false
      t.string :image_asset_key
      t.string :thumbnail_asset_key
      t.timestamps
    end
    add_index :furniture_template_previews, :uid, unique: true
    add_index :furniture_template_previews, %i[furniture_theme_uid display_order], unique: true,
      name: "index_furniture_previews_on_theme_and_display_order"
    add_foreign_key :furniture_template_previews, :furniture_themes,
      column: :furniture_theme_uid, primary_key: :uid, on_delete: :cascade

    add_column :furnitures, :in_catalog, :boolean, default: false, null: false
    add_column :furnitures, :theme_uid, :string
    add_column :furnitures, :image_asset_key, :string
    add_index :furnitures, :theme_uid
    add_foreign_key :furnitures, :furniture_themes,
      column: :theme_uid, primary_key: :uid, on_delete: :nullify

    create_table :furniture_catalog_states do |t|
      t.boolean :data_ready, default: false, null: false
      t.boolean :assets_ready, default: false, null: false
      t.integer :furniture_count, default: 0, null: false
      t.integer :theme_count, default: 0, null: false
      t.integer :preview_count, default: 0, null: false
      t.string :database_sha256
      t.datetime :imported_at
      t.datetime :assets_imported_at
      t.timestamps
    end
  end
end
