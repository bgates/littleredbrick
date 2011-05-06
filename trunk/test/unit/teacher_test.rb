require 'test_helper'

class TeacherTest < ActiveSupport::TestCase

  def setup
    @teacher = Teacher.new(:school_id => 1, :first_name => 'for', :last_name => 'test')
  end

  def test_admin
    assert !@teacher.admin?
    @teacher.admin = true
    assert @teacher.admin?
  end

  def test_admin_capacity
    assert !@teacher.can_act_as_admin?
    @teacher.roles << Role.create(:title => 'admin')
    @teacher.save(:validate => false)
    assert @teacher.can_act_as_admin?
  end

  def test_may_access_school_forums
    discussable = School.new
    %w(help school staff teachers parents).each do |klass|
      discussable.type = klass
      assert @teacher.may_access_forum_for?(discussable)
    end
  end

  def test_may_access_and_create_section_forums
    @section = Section.new
    @teacher.expects(:sections).times(2).returns([@section])
    assert @teacher.may_access_forum_for?(@section)
    assert @teacher.may_create_forum_for?(@section)
  end

  def test_admin_may_create_forums
    @teacher.expects(:admin?).at_least_once.returns(true)
    discussable = School.new
    %w(school staff teachers parents).each do |klass|
      discussable.type = klass
      assert @teacher.may_create_forum_for?(discussable)
    end
  end

  def test_teacher_limit
    @school = School.new(:teacher_limit => 1)
    @school.expects(:send_welcome_email).returns(true)
    @teacher = @school.teachers.build(:first_name => 'Bruce', :last_name => 'Willis')
    @school.contact = @teacher
    @school.save(:validate => false)
    assert @teacher.valid?
    @teacher = @school.teachers.create(:first_name => 'Bruce', :last_name => 'Hornsby')
    assert !@teacher.valid?
    assert !Teacher.find_by_last_name('Hornsby')
    assert_equal @school.teacher_limit, @school.teachers(true).size
  end

  def test_departments
    @teacher.expects(:sections).returns([mock(:subject_id => 1), mock(:subject_id => 2), mock(:subject_id => 1)])
    Subject.expects(:find).with([1,2]).returns([mock(:department_id => 3)])
    Department.expects(:find).with([3], :include => :subjects).returns('return value')
    assert_equal 'return value', @teacher.departments
  end

  def test_may_see_own_section
    @section = Section.new
    @teacher.expects(:teaches?).with(@section).returns(true)
    assert @teacher.may_see?(@section)
  end

  def test_may_see_other_section_or_teacher_as_admin
    @section = Section.new(:teacher_id => 'other')
    @other = Teacher.new
    @teacher.stubs(:admin?).returns(true)
    assert @teacher.may_see?(@section)
    assert @teacher.may_see?(@other)
  end

  def test_may_not_see_other_section_or_teacher
    @section = Section.new(:teacher_id => 'other')
    @other = Teacher.new
    assert !@teacher.may_see?(@section)
    assert !@teacher.may_see?(@other)
  end

  def test_events
    @teacher.stubs(:section_ids).returns [2, 3, 4]
    @teacher.stubs(:section_or_school_track).returns :track
    @start, @finish = Date.today - 15, Date.today + 15
    @personal_event = mock(:date => Date.today + 5)
    @academic_event = mock(:date => Date.today - 10)
    @teacher.expects(:universal_events).with(@start, @finish, :track).returns([@personal_event])
    Event.stubs(:where).with(["invitable_type = 'Section' AND invitable_id IN (?) AND date BETWEEN ? AND ?", [2,3,4], @start, @finish]).returns([@academic_event])
    @assignment = mock(:date => Date.today - 5)
    Event.stubs(:where).with(["invitable_type IN (?) AND invitable_id = ? AND date BETWEEN ? AND ?", %w(Teachers Staff), 1, @start, @finish]).returns([])
    Assignment.expects(:where).with(["(date_due BETWEEN ? AND ?) AND section_id IN (?)", @start, @finish, [2,3,4]]).returns(mock(:order => [@assignment]))
    assert_equal [@academic_event, @assignment, @personal_event], @teacher.all_events(@start, @finish, true)
  end

  def test_change_admin_status
    @teacher.make_admin
    assert @teacher.can_act_as_admin?
    @teacher.revoke_admin
    assert !@teacher.can_act_as_admin?
  end
end

