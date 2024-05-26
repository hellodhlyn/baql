# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.1].define(version: 2024_05_26_080208) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "events", force: :cascade do |t|
    t.string "event_id", null: false
    t.string "name", null: false
    t.string "type", null: false
    t.boolean "rerun", null: false
    t.datetime "since", null: false
    t.datetime "until", null: false
    t.string "image_url"
    t.jsonb "videos"
    t.jsonb "pickups"
    t.jsonb "tips"
    t.boolean "visible", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_events_on_event_id", unique: true
    t.index ["since"], name: "index_events_on_since"
  end

  create_table "raids", force: :cascade do |t|
    t.string "raid_id", null: false
    t.string "name", null: false
    t.string "boss", null: false
    t.string "type", null: false
    t.string "terrain"
    t.string "attack_type"
    t.string "defense_type"
    t.datetime "since", null: false
    t.datetime "until", null: false
    t.boolean "visible", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raid_id"], name: "index_raids_on_raid_id", unique: true
    t.index ["since"], name: "index_raids_on_since"
  end

end
