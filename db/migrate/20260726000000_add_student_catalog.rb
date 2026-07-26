class AddStudentCatalog < ActiveRecord::Migration[8.0]
  def up
    create_table :student_catalogs do |t|
      t.string :region, null: false
      t.string :version, null: false
      t.string :client_version
      t.string :database_sha256, null: false
      t.jsonb :data, null: false, default: {}
      t.timestamps

      t.index :region, unique: true
      t.index :version
    end

    add_column :students, :catalog_data, :jsonb, null: false, default: {}

    add_column :student_skills, :uid, :string
    add_column :student_skills, :localizations, :jsonb, null: false, default: {}
    add_column :student_skills, :levels, :jsonb, null: false, default: []
    add_column :student_skills, :links, :jsonb, null: false, default: {}
    add_column :student_skills, :icon_asset_key, :string

    execute <<~SQL
      UPDATE student_skills
      SET uid = 'legacy:' || skill_type
      WHERE uid IS NULL
    SQL

    change_column_null :student_skills, :uid, false
    remove_index :student_skills, [:student_uid, :skill_type]
    add_index :student_skills, [:student_uid, :uid], unique: true
    add_index :student_skills, [:student_uid, :skill_type]
  end

  def down
    remove_index :student_skills, [:student_uid, :skill_type]
    remove_index :student_skills, [:student_uid, :uid]
    add_index :student_skills, [:student_uid, :skill_type], unique: true

    remove_column :student_skills, :icon_asset_key
    remove_column :student_skills, :links
    remove_column :student_skills, :levels
    remove_column :student_skills, :localizations
    remove_column :student_skills, :uid
    remove_column :students, :catalog_data
    drop_table :student_catalogs
  end
end
