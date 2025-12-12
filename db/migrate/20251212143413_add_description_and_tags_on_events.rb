class AddDescriptionAndTagsOnEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :summary, :text, null: true
    add_column :events, :description, :text, null: true
    add_column :events, :tags, :string, array: true, default: []

    add_column :students, :tactic_role, :string
    add_column :students, :position, :string
    add_column :students, :birthday, :date, null: true
    add_column :students, :alt_names, :string, array: true, default: []

    remove_column :raids, :defense_type
  end
end
