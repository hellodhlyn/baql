class Student < ApplicationRecord
  include Translatable

  BAQL_ID_PREFIX = "baql::students::"
  TACTIC_ROLES = %w[attacker tank support healer tactical_support].freeze
  POSITIONS = %w[back front middle].freeze

  translatable :name

  Gear = Data.define(:name, :growth_items)
  GearGrowthItem = Data.define(:gear_tier, :item, :amount)

  has_many :student_skills, primary_key: :uid, foreign_key: :student_uid, dependent: :delete_all
  has_many :student_gear_growth_items, primary_key: :uid, foreign_key: :student_uid, dependent: :delete_all

  after_save :flush_cache

  scope :all_without_multiclass, -> { where("multiclass_uid is null or multiclass_uid = uid") }

  def self.find_by_uid(uid)
    Rails.cache.fetch(cache_key(uid), expires_in: 1.minute) do
      self.find_by(uid: uid)
    end
  end

  def self.multiclass_students
    self.where("multiclass_uid is not null")
  end

  def self.sync_recruitment_dates!(uids)
    Array(uids).compact.uniq.each do |uid|
      student = lock.find_by(uid: uid)
      next unless student

      student.update!(
        release_at: first_recruitment_start_at(uid),
        archive_at: first_archive_recruitment_start_at(uid),
      )
    end
  end

  def released
    self.release_at.present? && self.release_at < Time.zone.now
  end

  def equipments
    super&.split(",") || []
  end

  def name(lang = Constants::DEFAULT_LANGUAGE)
    Translation.find_by(key: "#{translation_key_prefix}::name", language: lang)&.value || read_attribute(:name)
  end

  def translation_key_prefix
    "#{BAQL_ID_PREFIX}#{uid}"
  end

  def skills(skill_type: nil)
    records = student_skills
    records = records.where(skill_type: skill_type) if skill_type.present?
    records.to_a.sort_by { |skill| [StudentSkill::TYPE_ORDER.fetch(skill.skill_type), skill.uid] }
  end

  def gear
    return nil if gear_name.blank?

    growth_items = student_gear_growth_items.includes(:item).filter_map do |growth_item|
      next unless growth_item.item

      GearGrowthItem.new(
        gear_tier: growth_item.gear_tier,
        item: growth_item.item,
        amount: growth_item.amount,
      )
    end

    Gear.new(name: gear_name, growth_items: growth_items)
  end

  private

  def self.recruitments_for_student(uid)
    Recruitment
      .joins(:recruitment_group)
      .where(student_uid: uid)
  end

  def self.first_recruitment_start_at(uid)
    recruitments_for_student(uid)
      .reorder("recruitment_groups.start_at ASC", "recruitment_groups.uid ASC")
      .pick("recruitment_groups.start_at")
  end

  def self.first_archive_recruitment_start_at(uid)
    recruitments_for_student(uid)
      .where(recruitment_type: Recruitment::ARCHIVE_RECRUITMENT_TYPES)
      .reorder("recruitment_groups.start_at ASC", "recruitment_groups.uid ASC")
      .pick("recruitment_groups.start_at")
  end

  def self.cache_key(uid)
    "students::#{uid}"
  end

  def flush_cache
    Rails.cache.delete(self.class.cache_key(uid))
  end
end
