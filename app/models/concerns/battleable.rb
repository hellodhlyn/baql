module Battleable
  extend ActiveSupport::Concern

  included do
    ATTACK_TYPES  = ["normal", "explosive", "piercing", "mystic", "sonic", "chemical"]
    DEFENSE_TYPES = ["normal", "light", "heavy", "special", "elastic", "composite"]
    TERRAINS      = ["outdoor", "indoor", "street"]
  end
end
