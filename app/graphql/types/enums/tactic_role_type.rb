module Types
  module Enums
    class TacticRoleType < Types::Base::Enum
      Student::TACTIC_ROLES.each do |role|
        value role, value: role
      end
    end
  end
end
