class CreatePickups < ActiveRecord::Migration[8.0]
  def change
    create_table :pickups do |t|
      t.string :student_uid, null: true
      t.string :fallback_student_name, null: false
      t.string :event_uid, null: false
      t.string :pickup_type, null: false
      t.datetime :since, null: false
      t.datetime :until, null: false
      t.boolean :rerun, null: false
      t.timestamps
    end

    add_index :pickups, :student_uid
    add_index :pickups, :event_uid

    execute <<-SQL
      INSERT INTO pickups (
        student_uid,
        fallback_student_name,
        event_uid,
        pickup_type,
        since,
        until,
        rerun,
        created_at,
        updated_at
      )
      SELECT
        pickup->>'studentId' as student_uid,
        COALESCE(
          pickup->>'studentName',
          (SELECT name FROM students WHERE student_id = pickup->>'studentId')
        ) as fallback_student_name,
        event_id as event_uid,
        pickup->>'type' as pickup_type,
        since,
        until,
        (pickup->>'rerun')::boolean as rerun,
        NOW() as created_at,
        NOW() as updated_at
      FROM events,
      jsonb_array_elements(pickups) as pickup
      WHERE pickups IS NOT NULL
      ORDER BY since ASC;
    SQL

    remove_column :events, :pickups
  end
end
