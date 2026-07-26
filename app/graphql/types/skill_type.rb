module Types
  class SkillType < Types::Base::Object
    class SkillModifierActivationEnum < Types::Base::Enum
      graphql_name "StudentSkillModifierActivation"

      value "UNCONDITIONAL", value: "unconditional"
      value "CONDITIONAL", value: "conditional"
    end

    class SkillModifierPersistenceEnum < Types::Base::Enum
      graphql_name "StudentSkillModifierPersistence"

      value "PERMANENT", value: "permanent"
      value "TEMPORARY", value: "temporary"
    end

    class SkillStatModifierType < Types::StudentCatalogType::JsonObject
      graphql_name "StudentSkillStatModifier"

      field :stat, Types::StudentCatalogType::StudentStatEnum, null: false
      field :kind, Types::StudentCatalogType::StatModifierKindEnum, null: false
      field :value, Int, null: false
      field :activation, SkillModifierActivationEnum, null: false
      field :persistence, SkillModifierPersistenceEnum, null: false
    end

    class SkillLevelType < Types::StudentCatalogType::JsonObject
      graphql_name "StudentSkillLevel"

      field :level, Int, null: false
      field :cost, Int, null: true
      field :stat_modifiers, [SkillStatModifierType, null: false], null: false

      def stat_modifiers
        value(:stat_modifiers, [])
      end
    end

    class SkillDescriptionParameterValueType < Types::StudentCatalogType::JsonObject
      graphql_name "StudentSkillDescriptionParameterValue"

      field :level, Int, null: false
      field :text, String, null: false
    end

    class SkillDescriptionParameterType < Types::StudentCatalogType::JsonObject
      graphql_name "StudentSkillDescriptionParameter"

      field :id, Int, null: false
      field :emphasized, Boolean, null: false
      field :values, [SkillDescriptionParameterValueType, null: false], null: false
    end

    class SkillDescriptionType < Types::StudentCatalogType::JsonObject
      graphql_name "StudentSkillDescription"

      field :template, String, null: false
      field :parameters, [SkillDescriptionParameterType, null: false], null: false
    end

    class SelectableSkillType < Types::StudentCatalogType::JsonObject
      graphql_name "StudentSelectableSkill"

      field :condition, Types::StudentCatalogType::SkillSelectionConditionEnum, null: false
      field :skill_uid, String, null: false
    end

    field :uid, String, null: false
    field :skill_type, Types::Enums::StudentSkillTypeEnum, null: false
    field :name, String, null: false do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :icon_url, String, null: true
    field :max_level, Int, null: false
    field :levels, [SkillLevelType, null: false], null: false
    field :description, SkillDescriptionType, null: true do
      argument :lang, Types::Enums::LanguageType, required: false, default_value: Constants::DEFAULT_LANGUAGE
    end
    field :additional_skill_uids, [String, null: false], null: false
    field :selectable_skills, [SelectableSkillType, null: false], null: false

    def name(lang:)
      object.name(lang)
    end

    def icon_url
      return nil if object.icon_asset_key.blank?

      base_url = ENV["ASSET_BASE_URL"].to_s
      raise GraphQL::ExecutionError, "ASSET_BASE_URL is not configured" if base_url.blank?

      "#{base_url.chomp("/")}/#{object.icon_asset_key.sub(%r{\A/+}, "")}"
    end

    def max_level
      object.levels.map { |row| row.fetch("level") }.max || 0
    end

    def description(lang:)
      object.description(lang)
    end

    def additional_skill_uids
      object.links.fetch("additional_skill_uids", [])
    end

    def selectable_skills
      object.links.fetch("selectable_skills", [])
    end
  end
end
