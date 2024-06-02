module Battleable
  extend ActiveSupport::Concern

  included do
    ATTACK_TYPES  = ["explosive", "piercing", "mystic", "sonic"]
    DEFENSE_TYPES = ["light", "heavy", "special", "elastic"]
  end
end
