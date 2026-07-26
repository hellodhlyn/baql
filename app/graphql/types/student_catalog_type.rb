# frozen_string_literal: true

module Types
  class StudentCatalogType < Types::Base::Object
    class JsonObject < Types::Base::Object
      private

      def value(key, default = nil)
        return object.public_send(key) if object.respond_to?(key)

        object.fetch(key.to_s) { object.fetch(key.to_sym, default) }
      end

      def localized_value(lang, key)
        localizations = value(:localizations, {})
        localized = localizations[lang.to_s] || localizations[Constants::DEFAULT_LANGUAGE] || {}
        localized[key.to_s]
      end

      def asset_url(key)
        return nil if key.blank?

        base_url = ENV["ASSET_BASE_URL"].to_s
        raise GraphQL::ExecutionError, "ASSET_BASE_URL is not configured" if base_url.blank?

        "#{base_url.chomp("/")}/#{key.to_s.sub(%r{\A/+}, "")}"
      end
    end

    class StatGrowthTypeEnum < Types::Base::Enum
      graphql_name "StudentCatalogStatGrowthType"

      value "STANDARD", value: "standard"
      value "PREMATURE", value: "premature"
      value "LATE_BLOOM", value: "late_bloom"
      value "OBSTACLE", value: "obstacle"
      value "TIME_ATTACK", value: "time_attack"
    end

    class TerrainAdaptationRankEnum < Types::Base::Enum
      graphql_name "StudentTerrainAdaptationRank"

      %w[D C B A S SS].each { |rank| value rank, value: rank.downcase }
    end

    class StatModifierKindEnum < Types::Base::Enum
      graphql_name "StudentCatalogStatModifierKind"

      value "BASE", value: "base"
      value "COEFFICIENT", value: "coefficient"
      value "SPECIAL", value: "special"
    end

    class StudentStatEnum < Types::Base::Enum
      graphql_name "StudentCatalogStat"

      %w[
        max_hp
        attack_power
        defense_power
        heal_power
        critical_point
        critical_chance_rate
        critical_damage_rate
        sight_range
        max_bullet_count
        hp_recover_on_kill
        street_battle_adaptation
        outdoor_battle_adaptation
        indoor_battle_adaptation
        heal_effectiveness_rate
        critical_chance_resist_point
        critical_damage_resist_rate
        ex_skill_upgrade
        oppression_power
        oppression_resist
        stability_point
        accuracy_point
        dodge_point
        move_speed
        normal_attack_speed
        defense_penetration
        defense_penetration_resist
        extend_buff_duration
        extend_debuff_duration
        extend_crowd_control_duration
        enhance_explosion_rate
        enhance_pierce_rate
        enhance_mystic_rate
        enhance_light_armor_rate
        enhance_heavy_armor_rate
        enhance_unarmed_rate
        enhance_siege_rate
        enhance_normal_rate
        enhance_structure_rate
        enhance_normal_armor_rate
        damage_ratio2_increase
        damage_ratio2_decrease
        damaged_ratio2_increase
        damaged_ratio2_decrease
        enhance_sonic_rate
        enhance_elastic_armor_rate
        ignore_delay_count
        weapon_range
        block_rate
        ammo_cost
        regen_cost
        max_cost_increase
        heal_rate
        enhance_chemical_rate
        enhance_composite_armor_rate
        enhance_ex_damage_rate
        enhance_basics_damage_rate
        reduce_weak_damaged_rate
        range
        ammo_count
        critical_resist_point
        stability_rate
        damage_ratio
        damaged_ratio
      ].each { |stat| value stat.upcase, value: stat }
    end

    class SkillSelectionConditionEnum < Types::Base::Enum
      graphql_name "StudentSkillSelectionCondition"

      value "SELF", value: "self"
      value "ENEMY", value: "enemy"
    end

    class GrowthRatioType < JsonObject
      graphql_name "StudentCatalogGrowthRatio"

      field :growth_type, StatGrowthTypeEnum, null: false
      field :value, Int, null: false
    end

    class StatLevelInterpolationType < JsonObject
      graphql_name "StudentCatalogStatLevelInterpolation"

      field :level, Int, null: false
      field :ratios, [GrowthRatioType, null: false], null: false
    end

    class StatModifierType < JsonObject
      graphql_name "StudentCatalogStatModifier"

      field :stat, StudentStatEnum, null: false
      field :kind, StatModifierKindEnum, null: false
      field :value, Int, null: false
    end

    class LevelStatType < JsonObject
      graphql_name "StudentCatalogLevelStat"

      field :stat, StudentStatEnum, null: false
      field :level1, Int, null: false
      field :level100, Int, null: false
    end

    class FixedStatType < JsonObject
      graphql_name "StudentCatalogFixedStat"

      field :stat, StudentStatEnum, null: false
      field :value, Int, null: false
    end

    class TerrainAdaptationFactorType < JsonObject
      graphql_name "StudentCatalogTerrainAdaptationFactor"

      field :rank, TerrainAdaptationRankEnum, null: false
      field :attack_power_factor, Int, null: false
      field :accuracy_factor, Int, null: false
      field :dodge_factor, Int, null: false
      field :shot_factor, Int, null: false
      field :block_factor, Int, null: false
    end

    class EquipmentModifierType < JsonObject
      graphql_name "StudentCatalogEquipmentModifier"

      field :stat, StudentStatEnum, null: false
      field :kind, StatModifierKindEnum, null: false
      field :level1, Int, null: false
      field :level_max, Int, null: false
    end

    class EquipmentType < JsonObject
      graphql_name "StudentCatalogEquipment"

      field :uid, String, null: false
      field :category, String, null: false
      field :tier, Int, null: false
      field :max_level, Int, null: false
      field :growth_type, StatGrowthTypeEnum, null: false
      field :modifiers, [EquipmentModifierType, null: false], null: false
      field :name, String, null: false do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end
      field :description, String, null: true do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end

      def name(lang:)
        localized_value(lang, :name).presence || raise(GraphQL::ExecutionError, "equipment name is missing")
      end

      def description(lang:)
        localized_value(lang, :description)
      end

    end

    class StudentProfileType < JsonObject
      graphql_name "StudentCatalogProfile"

      field :family_name, String, null: true
      field :personal_name, String, null: true
      field :introduction, String, null: true
      field :hobby, String, null: true
      field :age, String, null: true
      field :school_year, String, null: true
      field :height, String, null: true
      field :weapon_name, String, null: true
    end

    class StudentStatProfileType < JsonObject
      graphql_name "StudentCatalogStatProfile"

      field :growth_type, StatGrowthTypeEnum, null: false
      field :level_stats, [LevelStatType, null: false], null: false
      field :fixed_stats, [FixedStatType, null: false], null: false
    end

    class StudentTerrainAdaptationsType < JsonObject
      graphql_name "StudentCatalogTerrainAdaptations"

      field :street, TerrainAdaptationRankEnum, null: false
      field :outdoor, TerrainAdaptationRankEnum, null: false
      field :indoor, TerrainAdaptationRankEnum, null: false
    end

    class StarBonusType < JsonObject
      graphql_name "StudentCatalogStarBonus"

      field :star, Int, null: false
      field :modifiers, [StatModifierType, null: false], null: false
    end

    class PotentialLevelType < JsonObject
      graphql_name "StudentCatalogPotentialLevel"

      field :level, Int, null: false
      field :rate, Int, null: false
    end

    class PotentialBonusType < JsonObject
      graphql_name "StudentCatalogPotentialBonus"

      field :stat, StudentStatEnum, null: false
      field :unnecessary, Boolean, null: false
      field :levels, [PotentialLevelType, null: false], null: false
    end

    class FavorRewardType < JsonObject
      graphql_name "StudentCatalogFavorReward"

      field :level, Int, null: false
      field :modifiers, [StatModifierType, null: false], null: false
    end

    class WeaponStageType < JsonObject
      graphql_name "StudentCatalogWeaponStage"

      field :stage, Int, null: false
      field :unlocked, Boolean, null: false
      field :max_level, Int, null: false
      field :learn_skill_slot, Types::Enums::StudentSkillTypeEnum, null: true
      field :learn_skill_position, Int, null: true
      field :modifiers, [StatModifierType, null: false], null: false
    end

    class StudentWeaponType < JsonObject
      graphql_name "StudentCatalogWeapon"

      field :name, String, null: false do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end
      field :description, String, null: true do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end
      field :image_url, String, null: true
      field :growth_type, StatGrowthTypeEnum, null: false
      field :level_stats, [LevelStatType, null: false], null: false
      field :stages, [WeaponStageType, null: false], null: false

      def name(lang:)
        localized_value(lang, :name).presence || raise(GraphQL::ExecutionError, "weapon name is missing")
      end

      def description(lang:)
        localized_value(lang, :description)
      end

      def image_url
        asset_url(value(:image_asset_key))
      end
    end

    class GearTierType < JsonObject
      graphql_name "StudentCatalogGearTier"

      field :tier, Int, null: false
      field :open_favor_level, Int, null: false
      field :max_level, Int, null: false
      field :growth_type, StatGrowthTypeEnum, null: false
      field :modifiers, [EquipmentModifierType, null: false], null: false
      field :learn_skill_slot, Types::Enums::StudentSkillTypeEnum, null: true
      field :learn_skill_position, Int, null: true
    end

    class StudentGearCatalogType < JsonObject
      graphql_name "StudentCatalogGear"

      field :name, String, null: false do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end
      field :description, String, null: true do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end
      field :tiers, [GearTierType, null: false], null: false

      def name(lang:)
        localized_value(lang, :name).presence || raise(GraphQL::ExecutionError, "gear name is missing")
      end

      def description(lang:)
        localized_value(lang, :description)
      end

    end

    class SkillReferenceType < JsonObject
      graphql_name "StudentCatalogSkillReference"

      field :position, Int, null: false
      field :skill_uid, String, null: true
    end

    class SkillConfigurationSlotType < JsonObject
      graphql_name "StudentCatalogSkillConfigurationSlot"

      field :slot, Types::Enums::StudentSkillTypeEnum, null: false
      field :skills, [SkillReferenceType, null: false], null: false
    end

    class SkillConfigurationType < JsonObject
      graphql_name "StudentCatalogSkillConfiguration"

      field :form_index, Int, null: false
      field :minimum_weapon_star, Int, null: false
      field :minimum_gear_tier, Int, null: false
      field :select_ex_skill_action_slot, Int, null: true
      field :slots, [SkillConfigurationSlotType, null: false], null: false
    end

    class StudentDataType < JsonObject
      graphql_name "StudentCatalogData"

      field :profile, StudentProfileType, null: false do
        argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
      end
      field :stat_profile, StudentStatProfileType, null: false
      field :terrain_adaptations, StudentTerrainAdaptationsType, null: false
      field :star_bonuses, [StarBonusType, null: false], null: false
      field :potential_bonuses, [PotentialBonusType, null: false], null: false
      field :favor_rewards, [FavorRewardType, null: false], null: false
      field :weapon, StudentWeaponType, null: false
      field :gear, StudentGearCatalogType, null: true
      field :skill_configurations, [SkillConfigurationType, null: false], null: false

      def profile(lang:)
        localizations = value(:profile, {}).fetch("localizations", {})
        localizations[lang.to_s] || localizations[Constants::DEFAULT_LANGUAGE] || {}
      end
    end

    field :version, String, null: false
    field :assets_version, String, null: true
    field :client_version, String, null: true
    field :database_sha256, String, null: false
    field :stat_level_interpolation_end_level, Int, null: false
    field :stat_level_interpolations, [StatLevelInterpolationType, null: false], null: false
    field :terrain_adaptation_factors, [TerrainAdaptationFactorType, null: false], null: false
    field :equipment, [EquipmentType, null: false], null: false

    def stat_level_interpolations
      object.data.fetch("stat_level_interpolations", [])
    end

    def stat_level_interpolation_end_level
      object.data.fetch("stat_level_interpolation_end_level")
    end

    def terrain_adaptation_factors
      object.data.fetch("terrain_adaptation_factors", [])
    end

    def equipment
      object.data.fetch("equipment", [])
    end
  end
end
