require 'test_helper'

class AssignmentTest < ActiveSupport::TestCase

  def test_due_date
    new_assignment
    assert_equal @assignment.date, @assignment.date_due
  end

  def test_individual_due_dates
    new_assignment(:date_due => nil, :individual_due_dates => true)
    assert @assignment.valid?
  end

  def test_check_grade_due_dates
    new_assignment(:date_due => nil, :individual_due_dates => true)
    @grade = @assignment.grades.build(:rollbook_entry_id => 1, :date_due => Date.today + 4)
    @grade.expects(:check_due_date).at_least_once.returns(true)
    assert @assignment.valid?
  end

  def test_grade_with_no_due_date
    new_assignment(:date_due => nil, :individual_due_dates => true, :new_grades => {1 => {:date_due => ''}})
    @grade = @assignment.grades.first
    assert !@grade.valid?
    assert !@assignment.valid?
  end

  def test_point_value
    new_assignment
    assert @assignment.point_value.is_a?(Integer)
  end

  def test_teacher
    @assignment = Assignment.new
    @assignment.stub_path('section.teacher').returns(:teacher)
    assert_equal @assignment.teacher, :teacher
  end

  def test_should_setup_assignment_with_no_error
    new_assignment
    assert @assignment.valid?
  end

  def test_date_due_must_be_after_assigned_date
    new_assignment(:date_assigned => Date.today.succ, :date_due => Date.today)
    assert !@assignment.valid?
    assert !@assignment.errors[:date_assigned].empty?
  end

  def test_must_have_numerical_point_value
    new_assignment(:point_value => 'xx')
    assert !@assignment.valid?
    assert !@assignment.errors[:point_value].empty?
  end

  def test_should_set_date_created_as_today
    new_assignment({:date_assigned => nil}, true)
    assert_equal Date.today, @assignment.date_assigned
  end

  def test_create_default_grade_for_enrolled_student
    new_assignment({}, true)
    assert_equal Grade.count, 1
    @grade = Grade.first
    assert_equal Grade::DEFAULT_SCORE, @grade.score
    assert_equal 3, @grade.rollbook_entry_id
  end

  def test_editing_assignment_changes_mp
    new_assignment({}, true)
    @grade = @assignment.grades[0]
    @grade.expects(:assignment_changes_marking_period)
    @assignment.update_attribute(:reported_grade_id, 2)
  end

  def test_invalid_assignment_change_does_not_change_mp
    new_assignment({}, true)
    @grade = @assignment.grades[0]
    @grade.expects(:assignment_changes_marking_period).times(0)
    @assignment.update_attributes(:point_value => 100, :date_due => Date.today - 100)
  end

  def test_some_attributes_do_not_change_mp
    new_assignment({}, true)
    @assignment = Assignment.find(@assignment)
    @grade = @assignment.grades[0]
    @grade.expects(:assignment_changes_marking_period).times(0)
    @assignment.update_attributes(:title => 'change', :description => 'change', :category => 'other', :date_due => Date.today + 100)
  end

  def test_destroy
    new_assignment({:position => 1}, true)
    assert_difference('Grade.count', -1) do
      @assignment.destroy
    end
  end

  def test_average_graded
    @assignment = Assignment.new(:point_value => 10.0)
    g1, g2, g3 = stub(:graded? => true, :score => 10), stub(:graded? => false), stub(:graded? => true, :score => 8)
    @assignment.expects(:grades).returns([g1, g2, g3])
    assert_equal 9.0, @assignment.average_score
    assert_in_delta 90, @assignment.average_pct, 0.001
  end

  def test_average_ungraded
    @assignment = Assignment.new
    @assignment.expects(:grades).at_least_once.returns([])
    assert_equal nil, @assignment.average_score
    assert_equal 'N/A', @assignment.average_pct
  end

  def test_scale
    new_assignment
    zero, graded, ungraded = stub(:graded? => true, :score => 0), stub(:graded? => true, :score => 5), stub(:graded? => false, :score => '-')
    @assignment.expects(:grades).returns([zero, graded, ungraded])
    @assignment.point_value = 10
    @assignment.expects(:point_value_was).returns(5)
    zero.expects(:scale).with(2.0)
    graded.expects(:scale).with(2.0)
    @assignment.send :scale_grades
  end

  def test_scale_down
    new_assignment({:point_value => '10'})
    odd, even = stub(:graded? => true, :score => '19'), stub(:graded? => true, :score => '20')
    @assignment.expects(:grades).returns([odd, even])
    @assignment.expects(:point_value_was).returns 20
    odd.expects(:scale).with(0.5)
    even.expects(:scale).with(0.5)
    @assignment.send :scale_grades
  end

  def test_scale_unevenly
    new_assignment(:point_value => '3')
    grade = stub(:graded? => true, :score => '7')
    @assignment.expects(:grades).returns([grade])
    @assignment.expects(:point_value_was).returns 8
    grade.expects(:scale).with(0.375)
    @assignment.send :scale_grades
  end

  def test_recent
    @assignment = Assignment.new(:date_due => Date.today - 1)
    assert @assignment.due_recently?
    assert !@assignment.due_soon?
  end

  def test_soon
    @assignment = Assignment.new(:date_due => Date.today + 5)
    assert @assignment.due_soon?
    assert !@assignment.due_recently?
  end

  def test_dateless
    @assignment = Assignment.new
    assert !@assignment.due_soon?
    assert !@assignment.due_recently?
  end

  def test_grades
    @assignment = Assignment.new(:date_due => Date.today, :date_assigned => Date.today - 5, :section_id => 1, :position => 1)
    @assignment.expects(:initialize_grades).returns(true)
    @assignment.save(:validate => false)
    2.times{|n| @assignment.grades.create(:rollbook_entry_id => n + 1)}
    @first = @assignment.grades[0]
    @last = @assignment.grades[1]
    grade_hash = {
     @first.id.to_s => { :date_due => Date.today - 1 },  @last.id.to_s => { :date_due => Date.today - 3 }
    }
    @assignment.grades = grade_hash
    assert_nil @assignment.date_due
    assert @assignment.individual_due_dates
    assert_equal Date.today - 1, @assignment.grades.first.date_due
    assert_equal Date.today - 3, @assignment.grades.last.date_due
    assert_equal Date.today - 5, @assignment.grades.last.date_assigned
  end

  def test_editable_by_teacher
    @assignment = Assignment.new
    @assignment.stubs(:section).returns(stub(:teacher_id => 1))
    @user = mock(:id => 1)
    assert @assignment.editable_by?(@user)

    @other = User.new
    assert !@assignment.editable_by?(@other)
  end

  def test_audience
    @assignment = Assignment.new
    @assignment.expects(:section).returns(mock(:name => 'class'))
    assert_equal 'class', @assignment.audience
  end

  def test_categories
    Assignment.expects(:select).with('DISTINCT assignments.category').returns([mock(:category => 'test')])
    assert_equal ['test'], Section.new.assignments.categories
  end

  def test_error_cleanup
    new_assignment(:date_due => nil, :individual_due_dates => true, :new_grades => {1 => {:date_due => ''}, 2 => {:date_due => 'error prone'}})
    assert !@assignment.valid?
    assert !@assignment.errors[:grades_date_due].empty?
  end

  def test_graded
    @assignment = Assignment.new
    @assignment.stubs(:grades).returns([Grade.new(:score => 1), Grade.new(:score => 2), Grade.new(:score => '-')])
    assert @assignment.graded?
  end

  def test_not_graded
    @assignment = Assignment.new
    @assignment.stubs(:grades).returns([Grade.new(:score => '-'), Grade.new(:score => '-'), Grade.new(:score => 1)])
    assert !@assignment.graded?
  end
protected

  def new_assignment(options = {}, stub_section = false)
    @assignment = Assignment.new({:section_id => 1,
                                  :title => 'What I programmed over summer vacation',
                                  :category => 'test', :point_value => '5',
                                  :date_assigned => Date.today, :date_due => Date.today.succ, :reported_grade_id => 1}.merge(options))
    if stub_section
      @section = stub(:rollbook_entries => [stub(:id => 3)])
      @assignment.expects(:section).returns(@section)
      @assignment.save
    end
  end

end

