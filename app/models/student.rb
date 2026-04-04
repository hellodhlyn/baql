class Student < ApplicationRecord
  include ImageSyncable

  Skill = Data.define(:skill_type, :name)

  SKILL_TYPES = {
    "Ex" => "ex",
    "Public" => "public",
    "Passive" => "passive",
    "ExtraPassive" => "extra_passive",
  }.freeze

  after_save :flush_cache

  scope :all_without_multiclass, -> { where("multiclass_uid is null or multiclass_uid = uid") }

  class SchaleDBMap
    ATTACK_TYPES = {
      "Explosion" => "explosive",
      "Pierce"    => "piercing",
      "Mystic"    => "mystic",
      "Sonic"     => "sonic",
      "Chemical"  => "chemical",
    }

    DEFENSE_TYPES = {
      "LightArmor"     => "light",
      "HeavyArmor"     => "heavy",
      "Unarmed"        => "special",
      "ElasticArmor"   => "elastic",
      "CompositeArmor" => "composite",
    }

    TACTIC_ROLES = {
      "DamageDealer" => "attacker",
      "Tanker"       => "tank",
      "Supporter"    => "support",
      "Healer"       => "healer",
      "Vehicle"      => "tactical_support",
    }

    POSITIONS = {
      "Back"   => "back",
      "Front"  => "front",
      "Middle" => "middle",
    }
  end

  def self.sync!
    existing_item_uids = Item.pluck(:uid).to_set

    SchaleDB::V1::Data.students.each do |uid, row|
      student = find_or_initialize_by(uid: uid)
      update_student_attributes(student, row)
      sync_skill_materials(student, row, existing_item_uids)
      log_and_sync_images_if_updated(student)
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

  def skills(skill_type: nil)
    skills = SKILL_TYPES.filter_map do |raw_skill_type, normalized_skill_type|
      name = raw_data.dig("Skills", raw_skill_type, "Name")
      next if name.blank?

      Skill.new(skill_type: normalized_skill_type, name: name)
    end

    return skills unless skill_type.present?

    skills.select { |skill| skill.skill_type == skill_type }
  end

  private

  def self.update_student_attributes(student, row)
    student.update!(
      name:         row["Name"],
      school:       row["School"].downcase.gsub(/^etc$/, "others"),
      initial_tier: row["StarGrade"],
      attack_type:  SchaleDBMap::ATTACK_TYPES[row["BulletType"]],
      defense_type: SchaleDBMap::DEFENSE_TYPES[row["ArmorType"]],
      role:         row["SquadType"] == "Main" ? "striker" : "special",
      position:     SchaleDBMap::POSITIONS[row["Position"]],
      tactic_role:  SchaleDBMap::TACTIC_ROLES[row["TacticRole"]],
      birthday:     parse_birthday(row["Birthday"]),
      equipments:   row["Equipment"].map(&:downcase).join(","),
      order:        row["DefaultOrder"],
      schale_db_id: row["PathName"],
      raw_data:     row,
    )
  end

  def self.parse_birthday(birthday_str)
    match = birthday_str&.match(/(\d+)월\s*(\d+)일/)
    return nil unless match

    month = match[1].to_i
    day = match[2].to_i

    Date.new(0, month, day)
  rescue ArgumentError
    nil
  end

  def self.sync_skill_materials(student, row, existing_item_uids)
    sync_skill_material_type(student, row["SkillExMaterial"], row["SkillExMaterialAmount"], "ex", existing_item_uids)
    sync_skill_material_type(student, row["SkillMaterial"], row["SkillMaterialAmount"], "normal", existing_item_uids)
  end

  def self.sync_skill_material_type(student, materials, amounts, skill_type, existing_item_uids)
    materials.each_with_index do |item_uids, index|
      level = index + 2
      item_uids.each_with_index do |item_uid, item_index|
        item_uid_str = item_uid.to_s
        next unless existing_item_uids.include?(item_uid_str)

        StudentSkillItem.find_or_initialize_by(
          student_uid: student.uid, 
          item_uid: item_uid_str, 
          skill_type: skill_type, 
          skill_level: level
        ).update!(amount: amounts[index][item_index])
      end
    end
  end

  def self.log_and_sync_images_if_updated(student)
    return unless student.saved_changes?

    Rails.logger.info("Student #{student.name}(#{student.uid}) has been updated")
    student.sync_images!
  end

  def self.cache_key(uid)
    "students::#{uid}"
  end

  def flush_cache
    Rails.cache.delete(self.class.cache_key(uid))
  end
end
