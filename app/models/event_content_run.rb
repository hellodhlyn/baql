class EventContentRun < ApplicationRecord
  RUN_TYPES = %w[first rerun].freeze

  belongs_to :event_content, primary_key: :uid, foreign_key: :event_content_uid
  has_many :run_stages, -> { order(:position) }, class_name: "EventContentRunStage", dependent: :delete_all
  has_many :bonuses, -> { order(:position) }, class_name: "EventContentRunBonus", dependent: :delete_all
  has_many :shop_resources, -> { order(:position) }, class_name: "EventContentRunShopResource", dependent: :delete_all
  has_many :minigames, -> { order(:position) }, class_name: "EventContentRunMinigame", dependent: :delete_all

  validates :event_content_uid, presence: true
  validates :run_type, inclusion: { in: RUN_TYPES }

  def stages_payload
    run_stages.map(&:as_payload)
  end

  def bonuses_payload
    bonuses.map(&:as_payload)
  end

  def shop_resources_payload
    shop_resources.map(&:as_payload)
  end

  def minigame_configs_payload
    minigames.map(&:config)
  end
end
