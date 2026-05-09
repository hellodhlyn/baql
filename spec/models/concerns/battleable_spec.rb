require "rails_helper"

RSpec.describe Battleable do
  it "exposes battle constants through including models" do
    expect(RaidSchedule::ATTACK_TYPES).to eq(described_class::ATTACK_TYPES)
    expect(RaidSchedule::DEFENSE_TYPES).to eq(described_class::DEFENSE_TYPES)
    expect(JointFiringDrill::TERRAINS).to eq(described_class::TERRAINS)
    expect(RaidSchedule::DIFFICULTIES).to eq(described_class::DIFFICULTIES)
  end
end
