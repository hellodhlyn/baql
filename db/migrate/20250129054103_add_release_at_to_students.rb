class AddReleaseAtToStudents < ActiveRecord::Migration[8.0]
  def change
    add_column :students, :release_at, :datetime

    initial_release_at = Time.zone.parse("2020-01-01 00:00:00")
    Student.all.each do |student|
      student.update!(release_at: initial_release_at) if student.read_attribute(:released)
    end

    remove_column :students, :released, :boolean
  end
end
