class Student < ApplicationRecord
  include ImageSyncable

  has_many :pickups, primary_key: :uid, foreign_key: :student_uid
  has_many :raid_statistics, primary_key: :uid, foreign_key: :student_uid
  has_many :skill_items, primary_key: :uid, foreign_key: :student_uid, class_name: "StudentSkillItem"

  after_save :flush_cache

  scope :all_without_multiclass, -> { where("multiclass_uid is null or multiclass_uid = uid") }

  class SchaleDBMap
    ATTACK_TYPES = {
      "Explosion" => "explosive",
      "Pierce"    => "piercing",
      "Mystic"    => "mystic",
      "Sonic"     => "sonic",
    }

    DEFENSE_TYPES = {
      "LightArmor"   => "light",
      "HeavyArmor"   => "heavy",
      "Unarmed"      => "special",
      "ElasticArmor" => "elastic",
    }
  end

  def self.sync!
    pickup_student_names = Pickup.where(student_uid: nil).pluck(:fallback_student_name)

    SchaleDB::V1::Data.students.each do |uid, row|
      student = Student.find_or_initialize_by(uid: uid)
      student.update!(
        name:         row["Name"],
        school:       row["School"].downcase.gsub(/^etc$/, "others"),
        initial_tier: row["StarGrade"],
        attack_type:  SchaleDBMap::ATTACK_TYPES[row["BulletType"]],
        defense_type: SchaleDBMap::DEFENSE_TYPES[row["ArmorType"]],
        role:         row["SquadType"] == "Main" ? "striker" : "special",
        equipments:   row["Equipment"].map(&:downcase).join(","),
        order:        row["DefaultOrder"],
        schale_db_id: row["PathName"],
      )

      row["SkillExMaterial"].each_with_index do |item_uids, index|
        level = index + 2
        item_uids.each_with_index do |item_uid, item_index|
          StudentSkillItem.find_or_initialize_by(student_uid: student.uid, item_uid: item_uid.to_s, skill_type: "ex", skill_level: level)
            .update!(amount: row["SkillExMaterialAmount"][index][item_index])
        end
      end

      row["SkillMaterial"].each_with_index do |item_uids, index|
        level = index + 2
        item_uids.each_with_index do |item_uid, item_index|
          StudentSkillItem.find_or_initialize_by(student_uid: student.uid, item_uid: item_uid.to_s, skill_type: "normal", skill_level: level)
            .update!(amount: row["SkillMaterialAmount"][index][item_index])
        end
      end

      if pickup_student_names.include?(student.name)
        pickup = Pickup.find_by(student_uid: nil, fallback_student_name: student.name)
        pickup.update!(student_uid: student.uid) if pickup
      end

      if student.saved_changes?
        Rails.logger.info("Student #{student.name}(#{student.uid}) has been updated")
        student.sync_images!
      end
    end

    nil
  end

  def self.find_by_uid(uid)
    Rails.cache.fetch(cache_key(uid), expires_in: 1.minute) do
      self.find_by(uid: uid)
    end
  end

  def self.multiclass_students
    self.where("multiclass_uid is not null")
  end

  def released
    self.release_at.present? && self.release_at < Time.zone.now
  end

  def equipments
    super&.split(",") || []
  end

  def sync_images!
    self.class.sync_image!("assets/images/students/standing/#{uid}", SchaleDB::V1::Images.student_standing(uid))
    self.class.sync_image!("assets/images/students/collection/#{uid}", SchaleDB::V1::Images.student_collection(uid))
    nil
  end

  private

  def self.cache_key(uid)
    "students::#{uid}"
  end

  def flush_cache
    Rails.cache.delete(self.class.cache_key(uid))
  end
end
