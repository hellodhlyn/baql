class AddAssetsVersionToStudentCatalogs < ActiveRecord::Migration[8.0]
  def change
    add_column :student_catalogs, :assets_version, :string
  end
end
