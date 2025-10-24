class EventShopResource < ApplicationRecord
  after_initialize :set_uid

  belongs_to :event, primary_key: :uid, foreign_key: :event_uid
  belongs_to :resource, polymorphic: true, primary_key: :uid, foreign_key: :resource_uid
  belongs_to :payment_resource, polymorphic: true, primary_key: :uid, foreign_key: :payment_resource_uid

  private

  def set_uid
    self.uid ||= SecureRandom.alphanumeric(12)
  end
end
