class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  protected

  def self.json_array_attr(attr_name, data_class, default: {})
    define_method(attr_name) do
      self.read_attribute(attr_name)&.map do |data|
        data.map { |k, v| [k.to_s.underscore, v] }
          .to_h
          .symbolize_keys
          .reverse_merge(default)
          .then { |object| data_class.new(**object) }
      end || []
    end
  end
end
