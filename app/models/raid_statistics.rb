# @deprecated Raid statistics are not served anymore
class RaidStatistics < ApplicationRecord
  belongs_to :raid
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid
end
