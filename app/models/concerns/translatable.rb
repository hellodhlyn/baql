module Translatable
  extend ActiveSupport::Concern

  class_methods do
    def translatable(*fields)
      fields.each do |field|
        define_method(field) do |lang = Constants::DEFAULT_LANGUAGE|
          Translation.find_by(key: "#{translation_key_prefix}::#{field}", language: lang)&.value
        end

        define_method(:"set_#{field}") do |value, lang = Constants::DEFAULT_LANGUAGE|
          Translation.find_or_initialize_by(key: "#{translation_key_prefix}::#{field}", language: lang)
                     .update!(value: value)
        end
      end
    end
  end
end
