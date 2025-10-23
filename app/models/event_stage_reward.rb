class EventStageReward < ApplicationRecord
  belongs_to :stage, class_name: "EventStage", primary_key: :uid, foreign_key: :stage_uid

  RewardBonus = Data.define(:student_uid, :ratio) do |data|
    def student = Student.find_by(uid: student_uid)
  end

  json_array_attr :bonuses, RewardBonus, default: []

  def item
    return nil unless reward_type == "item"
    @item ||= Item.find_by(uid: reward_uid)
  end
end
