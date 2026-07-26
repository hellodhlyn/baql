class StudentCatalog < ApplicationRecord
  CANONICAL_REGION = "japan"

  validates :region, presence: true, uniqueness: true
  validates :version, :database_sha256, presence: true

  def self.canonical
    find_by(region: CANONICAL_REGION)
  end
end
