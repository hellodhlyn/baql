module Battleable
  extend ActiveSupport::Concern

  included do
    ATTACK_TYPES  = ["explosive", "piercing", "mystic", "sonic", "chemical"]
    DEFENSE_TYPES = ["light", "heavy", "special", "elastic", "composite"]
  end
end
