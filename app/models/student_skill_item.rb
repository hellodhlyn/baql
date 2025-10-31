class StudentSkillItem < ApplicationRecord
  belongs_to :student, primary_key: :uid, foreign_key: :student_uid
  belongs_to :item, class_name: "Resources::Item", primary_key: :uid, foreign_key: :item_uid
end
