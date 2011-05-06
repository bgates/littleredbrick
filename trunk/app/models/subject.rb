class Subject < ActiveRecord::Base

  belongs_to              :department
  has_many                :sections, :dependent => :destroy

  validates_uniqueness_of :name, :scope => :department_id
  validates_presence_of   :name

  def self.with_department_and_school(dept, school)
    includes({:department => :subjects}).
    where(["departments.id = ? AND departments.school_id = ?", dept, school])
  end

  def enrollment(current = true)
    #RollbookEntry.count('student_id', :conditions => ["section_id IN (SELECT id FROM `sections` WHERE (subject_id  = ? AND current = ?))", id, current], :distinct => true)
    sections.sum(&:enrollment)
  end
end
