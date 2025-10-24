class Resource < ApplicationRecord
  def resource_type
    self.class.name.demodulize.underscore
  end
end
