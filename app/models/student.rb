class Student < ApplicationRecord
  after_save :flush_cache

  scope :all_without_multiclass, -> { where("multiclass_id is null or multiclass_id = student_id") }

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
    SchaleDB::V1::Data.students.each do |student_id, row|
      student = Student.find_or_initialize_by(student_id: student_id)
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

      Rails.logger.info("Student #{student.name}(#{student.student_id}) has been updated") if student.saved_changes?
    end

    nil
  end

  def self.find_by_student_id(student_id)
    Rails.cache.fetch(cache_key(student_id), expires_in: 1.minute) do
      self.find_by(student_id: student_id)
    end
  end

  def self.multiclass_students
    self.where("multiclass_id is not null")
  end

  def released
    self.release_at.present? && self.release_at < Time.zone.now
  end

  def equipments
    super&.split(",") || []
  end

  private

  def self.cache_key(student_id)
    "data::students::#{student_id}"
  end

  def flush_cache
    Rails.cache.delete(self.class.cache_key(student_id))
  end
end
