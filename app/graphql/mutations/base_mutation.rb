# frozen_string_literal: true

module Mutations
  class BaseMutation < GraphQL::Schema::RelayClassicMutation
    argument_class Types::Base::Argument
    field_class Types::Base::Field
    input_object_class Types::Base::InputObject
    object_class Types::Base::Object

    field :errors, [String], null: false

    def authorized?(**_args)
      unless context[:admin]
        raise GraphQL::ExecutionError, "Authentication required. Provide a valid Bearer token in the Authorization header."
      end
      super
    end

    private

    def save_record(record, success_fields = {})
      if record.save
        success_fields.merge(errors: [])
      else
        success_fields.transform_values { nil }.merge(errors: record.errors.full_messages)
      end
    end

    def find_record!(model_class, uid:)
      record = model_class.find_by(uid: uid)
      raise GraphQL::ExecutionError, "#{model_class.name} with uid '#{uid}' not found" unless record
      record
    end
  end
end
