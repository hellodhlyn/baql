module Queries
  class BaseQuery < GraphQL::Schema::Resolver
    argument_class Types::Base::Argument
  end
end
