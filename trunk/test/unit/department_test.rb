require 'test_helper'

class DepartmentTest < ActiveSupport::TestCase

  def setup
    @catalog = Department::CATALOG
  end

  def test_generic_choices
    @departments = Department.generic_choices(nil)
    assert_equal @catalog.length, @departments.length
    assert_equal @catalog['Mathematics'], @departments.detect{|dep| dep.name == 'Mathematics'}.subjects.collect(&:name)
  end

  def test_generic_elementary
    @departments = Department.generic_choices('elementary')
    assert_equal Department::ELEMENTARY, @departments[0].subjects.collect(&:name)
  end

  def test_find_sections_and_teachers_empty_dept
    @subjectless_department = Department.new
    assert_equal [], @subjectless_department.sections
    assert_equal [], @subjectless_department.teachers
    @department = Department.new
    @department.expects(:subjects).times(2).returns([stub(:id => 10), stub(:id => 100)])
    assert_equal [], @department.sections
    assert_equal [], @department.teachers
  end

  def test_find_teachers
    @department = Department.new
    @department.expects(:sections).returns([stub(:teacher_id => 100), stub(:teacher_id => 200)])
    Teacher.expects(:where).with(['id IN (?)', [100, 200]]).returns('teachers')
    assert_equal 'teachers', @department.teachers
  end

  def test_find_sections
    Section.expects(:where).with(['subject_id IN (?)', [1,2,3]]).returns('list of sections')
    @department = Department.new
    @department.expects(:subjects).returns([stub(:id => 1), stub(:id => 2), stub(:id => 3)])
    assert_equal 'list of sections', @department.sections
  end

  def test_enrollment
    Section.delete_all
    RollbookEntry.any_instance.expects(:set_grades_and_milestones).at_least_once.returns(true)
    @department = Department.create(:school_id => 1, :name => 'Test', :subjects_attributes => [{:name => 'first_subject'}])
    2.times{|n| @department.subjects.create(:name => 'subject' + n.to_s)}
    @department.subjects.each do |sub|
      2.times{|n| sub.sections.create(:track_id => n, :teacher_id => n, :current => true)}
    end
    @department.sections.each_with_index do |section, i|
      3.times{|n|RollbookEntry.create(:section_id => section.id, :student_id => i + 10**n)}
    end
    assert_equal 18, @department.enrollment
  end
  
  def test_new_subjects
    @department = Department.create(:school_id => 1, :name => 'department', :subjects_attributes => {0 => {:name => 'New'}, 1 => {:name => 'Other'}, 2 => {:name => ''} })
    assert_equal 2, @department.subjects(true).length
    @subject = @department.subjects[0]
    assert_equal 'New', @subject.name
    assert @department.valid?
    assert @subject.valid?
  end

  def test_existing_subject_updating
    @department = Department.create(:school_id => 1, :name => 'department', :subjects_attributes => [{:name => 'first'}, {:name => 'second'}])
    id = @department.subjects[0].id.to_s
    assert @department.update_attributes(:subjects_attributes => {id => {:name => 'uno'}})
    assert @department.subjects.find_by_name('uno')
  end
end

