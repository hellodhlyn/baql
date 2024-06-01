class CreateStudents < ActiveRecord::Migration[7.1]
  def change
    create_table :students do |t|
      t.string :student_id, null: false
      t.string :name, null: false
      t.string :school, null: false
      t.integer :initial_tier, null: false
      t.string :attack_type, null: false
      t.string :defense_type, null: false
      t.string :role, null: false
      t.string :equipments
      t.boolean :released, null: false, default: false
      t.bigint :order, null: false
      t.timestamps

      t.index :student_id, unique: true
    end
  end
end
