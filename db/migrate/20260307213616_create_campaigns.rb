# frozen_string_literal: true

class CreateCampaigns < ActiveRecord::Migration[8.0]
  def change
    create_table :campaigns do |t|
      t.string   :uid,        null: false
      t.string   :region,     null: false
      t.string   :category,   null: false, array: true, default: []
      t.integer  :multiplier, null: false
      t.datetime :start_at,   null: false
      t.datetime :end_at,     null: false

      t.timestamps

      t.index [:uid, :region], unique: true
    end
  end
end
