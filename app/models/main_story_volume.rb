class MainStoryVolume < ApplicationRecord
  include Translatable

  has_many :chapters, class_name: "MainStoryChapter", foreign_key: :volume_uid, primary_key: :uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :sort_order, presence: true
  validates :label, presence: true

  BAQL_ID_PREFIX = "baql::main_story_volumes::"

  translatable :name

  def translation_key_prefix
    baql_id
  end
end
