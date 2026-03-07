class CreateRecruitmentGroupsAndRecruitments < ActiveRecord::Migration[8.0]
  def change
    create_table :recruitment_groups do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :content_type
      t.string :content_uid
      t.datetime :start_at, null: false
      t.datetime :end_at
      t.timestamps

      t.index :uid, unique: true
      t.index [:content_type, :content_uid]
    end

    create_table :recruitments do |t|
      t.string :uid, null: false
      t.string :baql_id, null: false
      t.string :recruitment_group_uid, null: false
      t.string :student_uid
      t.string :student_name, null: false
      t.string :recruitment_type, null: false
      t.boolean :pickup, null: false, default: true
      t.boolean :rerun, null: false, default: false
      t.timestamps

      t.index :uid, unique: true
      t.index :recruitment_group_uid
      t.index :student_uid
    end
  end
end
