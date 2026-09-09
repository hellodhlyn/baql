class EventContentRunMission < ApplicationRecord
  belongs_to :event_content_run

  scope :ordered, -> { order(:position) }

  def description_for(language)
    requested = localizations[language.to_s]
    requested = nil unless requested.is_a?(Hash) && requested.key?("template")
    requested || localizations.fetch("ko")
  end
end
