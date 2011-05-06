require 'test_helper'

class SectionTest < ActiveSupport::TestCase
                                    
  def setup
    @section = Section.new
  end

  def test_create_math_section
    algebra = Subject.new(:name => 'algebra')
    algebra.expects(:department).at_least_once.returns('math')
    @section.expects(:subject).at_least_once.returns(algebra)
    assert_equal @section.name, algebra.name
    assert_equal @section.department, algebra.department
  end

  def test_belongs_to
    @section.expects(:subject).returns subject = Subject.new
    subject.expects(:department).returns department = Department.new
    department.expects(:school_id).returns(1)
    school = School.new
    school.expects(:id).returns(1)
    assert @section.belongs_to?(school)
  end

  def test_marks
    @section.expects(:reported_grades).returns([:first])
    @section.stub_path('term.reported_grades').returns([:second])
    ReportedGrade.expects(:sort).with([:first, :second]).returns([:first, :second])
    assert_equal [:first, :second], @section.marks
  end

  def test_grade_scale
    assert_equal 'C', @section.on_scale(75)
    assert_equal '-', @section.on_scale(nil)
  end

  def test_grade_ranges
    assert @section.grade_ranges.include?(60...70)
  end

  def test_name_and_time
    @section.stubs(:name).returns('test')
    assert_equal 'test', @section.name_and_time
    @section.time = '2'
    assert_equal 'test(Period 2)', @section.name_and_time
    assert_equal 'test(2)', @section.name_and_time(false)
  end

  def test_current_mp
    @section.expects(:marking_periods).returns(stub(:where => stub(:order => stub(:first => stub(:start => Date.today - 1)))))
    assert_equal Date.today - 1, @section.current_marking_period.start
  end

  def test_no_grade_in_scale
    @section.update_attributes(:track_id => 1, :teacher_id => 1, :subject_id => 1)
    @section.grade_scale={:grades => ['', '', ''], :bounds => %w(60 70)}
    @section.save
    assert_equal @section.errors[:grade_scale][0], 'needs at least two grades'
  end

  def test_pass_fail_grade_scale
    grade_scale(%w(Fail Pass), %w(60))
    assert @section.valid?
    assert_equal [[(-1/0.0...60), 'Fail'], [(60...(1/0.0)), 'Pass']], @section.grade_scale
  end

  def test_repeated_grade_scale
    grade_scale(%w(F F C B A), %w(60 70 80 90))
    assert_equal 'needs all grades to be unique.', @section.errors[:grade_scale][0]
  end

  def test_unordered_grade_scale
    grade_scale(%w(F D C B A), %w(70 60 80 90))
    assert_equal 'needs to have the grade ranges entered in order.', @section.errors[:grade_scale][0]
  end

  def test_seating_chart
    @rbes = [RollbookEntry.new, RollbookEntry.new]
    @section.stubs(:rollbook_entries).returns(@rbes)
    assert @section.has_no_seating_chart?
    @rbes.first.x, @rbes.first.y = 1, 1
    assert !@section.has_no_seating_chart?
  end

  def test_no_average
    assert_equal "<span title='No assignments graded for this marking period'>N/A</span>", @section.average
  end

  def test_average
    @section.expects(:grade_distribution).returns({1 => Milestone.new(:earned => 90, :possible => 100), 2 => Milestone.new(:earned => 0, :possible => 0), 3 => Milestone.new(:earned => 100, :possible => 100)})
    assert_equal 95.0, @section.average
  end

  def test_add_milestones
    @section.expects(:rollbook_entries).returns([@rbe = RollbookEntry.new])
    @rbe.milestones.expects(:create).with(:reported_grade_id => :rpg, :earned => 0, :possible => 0)
    @section.add_milestones(:rpg)
  end

  def test_point_distribution
    %w(homework tests).each do |category|
      5.times{|n| @section.assignments.build(:category => category, :point_value => 10 * n, :reported_grade_id => 1)}
    end
    @section.assignments.build(:category => 'tests', :point_value => 100, :reported_grade_id => 1)
    @section.assignments.expects(:current).returns(@section.assignments)
    assert_equal({'homework' => 100, 'tests' => 200}, @section.point_distribution)
  end

  def test_alphabetize #TODO: this doesn't really test effect of sort_by, the method must be restructured
    @student1 = stub(:last_name => 'A', :rbe_id => '0')
    @student2 = stub(:last_name => 'Z', :rbe_id => '1')
    @student3 = stub(:last_name => 'C', :rbe_id => '2')
    @list = [@student1, @student2, @student3]
    prep_list
    assert @section.sort_by(@list, {:commit => 'alphabetize'})
  end

  def test_list
    prep_list
    assert @section.sort_by(nil, {:list => %w(0 2 1)})
  end

  def test_last_assignment_empty
    assert_equal 'None assigned', @section.assignments._last.title
  end

  def test_last_assignment
    prep_assignments
    assert_equal @section.assignments._last, @recent
  end

  def test_current_assignments
    prep_assignments
    assert_equal [@ungraded, @recent, @future], @section.assignments.current
  end

  def test_next_assignment
    prep_assignments
    assert_equal @future, @section.assignments._next
  end

  def test_members
    User.expects(:paginate).with(:include => 'forum_activities', :conditions => ['forum_activities.discussable_type = ? AND forum_activities.discussable_id = ?', 'Section', 1], :page => 6).returns(@user = User.new)
    @section.expects(:id).returns(1)
    assert_equal @section.members(6), @user
  end

  def test_membership
    @section.expects(:enrollment).returns(10)
    assert_equal 11, @section.membership
  end

  def test_bulk_enrollment
    stub_bulk_enrollment
    assert_equal ['existant student'], @section.bulk_enroll("existant student  \n missing student", @school)
  end

  def test_bulk_enroll_last_first
    stub_bulk_enrollment
    assert_equal ['existant student'], @section.bulk_enroll("student, existant \n student, missing", @school)
  end

  protected
  def grade_scale(grades, bounds)
    @section.update_attributes(:track_id => 1, :teacher_id => 1, :subject_id => 1)
    @section.update_attributes(:grade_scale => {:grades => grades, :bounds => bounds})
  end

  def prep_list
    @rbes = Array.new(3){RollbookEntry.new}
    @rbes.each_with_index {|entry, i| entry.stubs(:id).returns(i)}
    @rbes.first.expects(:update_attributes).with(:position => 1)
    @rbes[1].expects(:update_attributes).with(:position => 3)
    @rbes.last.expects(:update_attributes).with(:position => 2)
    @section.expects(:rollbook_entries).returns(@rbes)
  end

  def prep_assignments
    @dateless = @section.assignments.build
    @next_mp = @section.assignments.build(:date_due => Date.today + 5, :reported_grade_id => 2)
    @ungraded = @section.assignments.build(:date_due => Date.today - 1, :reported_grade_id => 1, :title => 'ungraded')
    @recent = @section.assignments.build(:date_due => Date.today - 1, :reported_grade_id => 1, :title => 'recent')
    @future = @section.assignments.build(:date_due => Date.today + 1, :reported_grade_id => 1)
    @section.reported_grade_id = 1
    @ungraded.stubs(:graded?).returns(false)
    @recent.stubs(:graded?).returns(true)
  end

  def stub_bulk_enrollment
    @school = stub()
    @school.stubs(:students).returns(@students = stub())
    @students.stubs(:find_by_full_name).with('existant student').returns(@student = Student.new)
    @students.stubs(:find_by_full_name).with('missing student').returns(nil)
    @section.expects(:enroll).with(@student).returns(true)
  end
end

