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

    Event.all.each do |event|
      event.read_attribute(:pickups)&.each do |pickup|
        Pickup.create!(
          student_uid: pickup["studentId"],
          fallback_student_name: pickup["studentName"] || Student.find_by_student_id(pickup["studentId"])&.name,
          event_uid: event.event_id,
          pickup_type: pickup["type"],
          since: event.since,
          until: event.until,
          rerun: pickup["rerun"],
        )
      end
    end

    remove_column :events, :pickups
  end
end
