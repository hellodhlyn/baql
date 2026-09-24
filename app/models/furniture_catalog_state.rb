class FurnitureCatalogState < ApplicationRecord
  SINGLETON_ID = 1

  def self.current
    find_by(id: SINGLETON_ID)
  end

  def ready?
    data_ready? && assets_ready?
  end
end
