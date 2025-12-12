module Types
  module Enums
    class TacticRoleType < Types::Base::Enum
      Student::SchaleDBMap::TACTIC_ROLES.values.each do |role|
        value role, value: role
      end
    end
  end
end
