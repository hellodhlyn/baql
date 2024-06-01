class Student < ApplicationRecord
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
      Student.find_or_create_by!(student_id: row["Id"]) do |student|
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
      end
    end

    nil
  end

  def self.find_by_student_id(student_id)
    Rails.cache.fetch("data::students::#{student_id}", expires_in: 1.hour) do
      self.find_by(student_id: student_id)
    end
  end

  def equipments
    super&.split(",") || []
  end
end
