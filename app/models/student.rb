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
    SchaleDB::Data.students.each do |row|
      student = Student.find_or_initialize_by(student_id: row["Id"])
      student.update!(
        name:         row["Name"],
        school:       row["School"].downcase.gsub(/^etc$/, "others"),
        initial_tier: row["StarGrade"],
        attack_type:  SchaleDBMap::ATTACK_TYPES[row["BulletType"]],
        defense_type: SchaleDBMap::DEFENSE_TYPES[row["ArmorType"]],
        role:         row["SquadType"] == "Main" ? "striker" : "special",
        released:     row["IsReleased"][1],
        equipments:   row["Equipment"].map(&:downcase).join(","),
        order:        row["DefaultOrder"],
      )

      Rails.logger.info("Student #{student.name}(#{student.student_id}) has been updated") if student.saved_change_to_released?
    end

    nil
  end

  def self.find_by_student_id(student_id)
    Rails.cache.fetch(cache_key(student_id), expires_in: 1.hour) do
      self.find_by(student_id: student_id)
    end
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
