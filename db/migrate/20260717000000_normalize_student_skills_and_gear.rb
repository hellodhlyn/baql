class NormalizeStudentSkillsAndGear < ActiveRecord::Migration[8.0]
  def up
    create_table :student_skills do |t|
      t.string :student_uid, null: false
      t.string :skill_type, null: false
      t.string :name, null: false
      t.timestamps

      t.index [:student_uid, :skill_type], unique: true
    end

    add_column :students, :gear_name, :string

    create_table :student_gear_growth_items do |t|
      t.string :student_uid, null: false
      t.string :item_uid, null: false
      t.integer :gear_tier, null: false
      t.integer :amount, null: false
      t.timestamps

      t.index [:student_uid, :gear_tier, :item_uid], unique: true
      t.index :item_uid
    end

    backfill_normalized_data
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "normalized student tables and columns are retained by policy"
  end

  private

  def backfill_normalized_data
    execute <<~SQL
      INSERT INTO student_skills (student_uid, skill_type, name, created_at, updated_at)
      SELECT students.uid, skill.skill_type, skill.name, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
      FROM students
      CROSS JOIN LATERAL (
        VALUES
          ('ex', students.raw_data #>> '{Skills,Ex,Name}'),
          ('public', students.raw_data #>> '{Skills,Public,Name}'),
          ('passive', students.raw_data #>> '{Skills,Passive,Name}'),
          ('extra_passive', students.raw_data #>> '{Skills,ExtraPassive,Name}')
      ) AS skill(skill_type, name)
      WHERE NULLIF(skill.name, '') IS NOT NULL;

      UPDATE students
      SET gear_name = NULLIF(raw_data #>> '{Gear,Name}', '');

      INSERT INTO student_gear_growth_items (
        student_uid,
        item_uid,
        gear_tier,
        amount,
        created_at,
        updated_at
      )
      SELECT
        students.uid,
        TRIM(BOTH '"' FROM material.value::text),
        (tier.ordinality + 1)::integer,
        (
          students.raw_data #> '{Gear,TierUpMaterialAmount}'
          -> ((tier.ordinality - 1)::integer)
          ->> ((material.ordinality - 1)::integer)
        )::integer,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
      FROM students
      CROSS JOIN LATERAL jsonb_array_elements(
        COALESCE(students.raw_data #> '{Gear,TierUpMaterial}', '[]'::jsonb)
      ) WITH ORDINALITY AS tier(value, ordinality)
      CROSS JOIN LATERAL jsonb_array_elements(tier.value)
        WITH ORDINALITY AS material(value, ordinality)
      WHERE students.raw_data #> '{Gear,TierUpMaterialAmount}'
        -> ((tier.ordinality - 1)::integer)
        ->> ((material.ordinality - 1)::integer) IS NOT NULL;
    SQL
  end
end
