# frozen_string_literal: true

module Types
  class Base::InputObject < GraphQL::Schema::InputObject
    argument_class Types::Base::Argument
  end
end
