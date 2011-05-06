require 'test_helper'

class StudentTest < ActiveSupport::TestCase

  def test_create_parents
    prepare_student
    assert_equal @student.parents.length, 2
    assert @dad = Parent.find(:first, :include => :authorization, :conditions => ['authorizations.login = ?', 'teststudent_father'])
  end

  def test_destroy
    prepare_student
    @parents = @student.parents
    @student.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Student.find(@student.id) }
    @parents.each{|p| assert_raise(ActiveRecord::RecordNotFound) { Parent.find(p.id) }}
  end

  def test_keep_parent_with_other_child
    prepare_student
    @parent_keep, @parent_go = @student.parents[0], @student.parents[1]
    @parent_keep.expects(:children).returns(mock(:count => 2))
    assert_equal 1, @parent_go.children.count
    @student.destroy
    assert_raise(ActiveRecord::RecordNotFound) { Student.find(@student.id) }
    assert_raise(ActiveRecord::RecordNotFound) { Parent.find(@parent_go.id) }
    assert Parent.find(@parent_keep.id)
  end

  def test_parent_login
    prepare_student
    assert !@student.parent_login_checked?('father')
  end

  def test_parent_has_logged_in
    prepare_student
    Parent.any_instance.stubs(:never_logged_in?).returns(false)
    assert @student.parent_login_checked?('mother')
  end
  #def test_all_events
  #  @user = users(:enrolled_student)
  #  @events = @user.all_events(Date.today, Date.today + 30)
  #  assert_equal 4, @events.length
  #  assert !@events.include?(events(:future))
  #  assert !@events.include?(events(:other_section))
  #end

  def test_access_school_and_section_forums
    @student = Student.new
    @student.expects(:sections).returns([@section = Section.new])
    assert @student.may_access_forum_for?(@section)
    @discussable = School.new
    @discussable.type = 'school'
    assert @student.may_access_forum_for?(@discussable)
    ['school', @school].each{|s| assert !@student.may_create_forum_for?(s)}
  end

  def test_may_not_access_other_forums
    @student = Student.new
    %w(admin help parents staffers teachers).each do |klass|
      discussable = School.new(:type => klass)
      assert !@student.may_access_forum_for?(discussable)
      assert !@student.may_create_forum_for?(discussable)
    end
  end

  def test_assignments
    s1, s2, s3 = Section.new, Section.new, Section.new
    s1.stubs(:assignments).returns([:a1, :a2, :a3])
    s2.stubs(:assignments).returns([:a4, :a5, :a6])
    s3.stubs(:assignments).returns([:a7])
    @student = Student.new
    @student.expects(:sections).returns([s1, s2, s3])
    assert_equal [:a1, :a2, :a3, :a4, :a5, :a6, :a7], @student.assignments
  end

  def test_search
    Student.expects(:where).with(['school_id = ?', 1]).returns arel = mock
    arel.expects(:where).with(["(last_name ILIKE ? OR first_name ILIKE ? OR id_number = ?)", 'test name%', 'test name%', 0]).returns arel2 = mock
    arel2.expects(:where).with(['grade IN (?)',[9,10,11,12]]).returns arel3 = mock
    arel3.expects(:select).with("id, id_number, last_name, first_name, school_id, grade, type").returns arel4 = mock
    @enrolled, @unenrolled = stub(:id => 404), stub(:id => 1)
    arel4.expects(:order).with("last_name ASC").returns([@enrolled, @unenrolled])
    RollbookEntry.expects(:enrolled_student_ids_for).returns([stub(:student_id => 404), stub(:student_id => 4)])
    assert_equal Student.search(1, 5, 'test name', [9, 10, 11, 12]), [@unenrolled]
  end

  def test_find_variants
    Student.expects(:find_by_first_name_and_last_name).times(2).with('Stan', 'Marsh').returns(@student = mock())
    assert_equal @student, Student.find_by_full_name('Stan Marsh')
    assert_equal @student, Student.find_by_last_first('Marsh Stan')
  end

  def test_events
    prep_events
    Grade.stub_path('where.includes.order').returns [@grade]
    assert_same_elements [@first_section, @schoolwide, @assignment, @grade], @student.all_events(Date.today, Date.today + 7, true)
  end

  def test_events_no_assignments
    prep_events
    assert_equal [@first_section, @schoolwide].sort_by(&:id), @student.all_events(Date.today, Date.today + 7).sort_by(&:id)
  end

  def test_recent_posts
    @student = Student.new
    Post.expects(:of_interest_to).with(@student).returns :posts
    assert_equal @student.recent_posts_of_interest, :posts
  end

  protected
  def prepare_student
    Student.any_instance.stubs(:school).returns(School.new) 
    @student = Student.create(:first_name => 'test', :last_name => 'student', :school_id => 1)
  end

  def prep_events
    @student = Student.new(:school_id => 1)
    @student.expects(:section_or_school_track).returns Track.new
    @student.stubs(:section_ids).returns [10, 30]
    @student.stubs(:rollbook_entries).returns([stub(:id => 100, :section_id => 10), stub(:id => 300, :section_id => 30)])
    @first_section = Factory(:event, :invitable_id => 10)
    @schoolwide = Event.create(:name => 'school', :invitable_type => 'School', :invitable_id => 1, :date => Date.today + 5)
    Assignment.any_instance.stubs(:section).returns(Section.new)
    @assignment = Assignment.create(:section_id => 30, :title => 'quiz', :category => 'quiz', :date_assigned => Date.today - 3, :date_due => Date.today + 1, :point_value => 10)
    @dateless = Assignment.create(:section_id => 10, :title => 'x', :category => 'quiz', :date_assigned => Date.today, :individual_due_dates => true, :date_due => nil, :point_value => 10)
    @grade = Grade.create(:assignment_id => @dateless.id, :rollbook_entry_id => 100, :date_due => Date.today + 3)
  end
end

