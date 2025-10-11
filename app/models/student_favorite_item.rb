class StudentFavoriteItem < ApplicationRecord
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid
  belongs_to :item, primary_key: :uid, foreign_key: :item_uid

  def self.sync!
    raw_items = SchaleDB::V1::Data.items.select { |uid, item| item["Category"] == "Favor" }

    raw_students = SchaleDB::V1::Data.students
    raw_students.each do |student_uid, student|
      student_item_tags = student["FavorItemTags"] + student["FavorItemUniqueTags"]

      ActiveRecord::Base.transaction do
        raw_items.each do |item_uid, item|
          tag_count = (student_item_tags & item["Tags"]).size
          if item_uid == "5996" || item_uid == "5997"
            exp = 240
            favorite_level = 4
            favorited = false
          elsif item_uid == "5998" || item_uid == "5999"
            exp = 60
            favorite_level = 3
            favorited = false
          elsif item["Rarity"] == "SR"
            favorite_level = [tag_count + 1, 3].min
            exp = item["ExpValue"] * favorite_level
            favorited = favorite_level >= 2
          elsif item["Rarity"] == "SSR"
            favorite_level = [tag_count + 2, 4].min
            exp = 120 + item["ExpValue"] * (favorite_level - 2)
            favorited = favorite_level >= 3
          else
            puts "unknown rarity: #{item["Rarity"]} for item #{item_uid}"
            next
          end

          StudentFavoriteItem
            .find_or_initialize_by(student_uid: student_uid, item_uid: item_uid)
            .update!(exp: exp, favorite_level: favorite_level, favorited: favorited)
        end
      end
    end;

    nil
  end
end
