# DEPRECATED: Use the standalone models (Item, Currency, Equipment, Furniture) instead.
# This STI base class and its subclasses in app/models/resources/ are kept for backward
# compatibility only and will be removed in a future release.
class Resource < ApplicationRecord
  def resource_type
    self.class.name.demodulize.underscore
  end
end
