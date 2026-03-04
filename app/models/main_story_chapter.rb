class MainStoryChapter < ApplicationRecord
  include Translatable

  belongs_to :volume, class_name: "MainStoryVolume", foreign_key: :volume_uid, primary_key: :uid
  has_many :parts, class_name: "MainStoryPart", foreign_key: :chapter_uid, primary_key: :uid

  validates :uid, presence: true, uniqueness: true
  validates :baql_id, presence: true
  validates :chapter_number, presence: true

  BAQL_ID_PREFIX = "baql::main_story_chapters::"

  translatable :name

  def translation_key_prefix
    baql_id
  end
end
