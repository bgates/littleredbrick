require 'test_helper'

class GradeTest < ActiveSupport::TestCase

  def setup
    @grade = Grade.create(:rollbook_entry_id => 1)
  end

  def test_accept_default_grade
    assert @grade.valid?
    assert_equal @grade.score, Grade::DEFAULT_SCORE
  end

  def test_valid_due_date
    @grade.expects(:date_assigned).at_least_once.returns(Date.today - 1)
    @grade.date_due = Date.today
    @grade.check_date = true
    assert @grade.valid?
  end

  def test_invalid_due_date
    @grade.expects(:date_assigned).at_least_once.returns(Date.today + 1000)
    @grade.date_due = Date.today
    @grade.check_date = true
    assert !@grade.valid?
  end

  def test_assignment_attr
    @grade = Grade.new
    @assignment = Assignment.new(:date_due => Date.today, :section_id => 4)
    @grade.expects(:assignment).returns(@assignment)
    @assignment.expects(:section).returns 'section'
    assert_equal('section', @grade.section)
  end

  def test_accept_numerical_score_and_update_marking_period
    stub_assignment_and_milestone
    Grade.update(@grade, {:score => 5})
    assert_in_delta Milestone.find(@previous.id).earned, 5, 0.001
    assert_equal Milestone.find(@previous).possible, 10
    assert_in_delta @previous.earned + 5, Milestone.find(@previous).earned, 0.001
    assert_equal @previous.possible + @grade.point_value, Milestone.find(@previous).possible
  end

  def test_decimal_score_properly_updates_marking_period
    stub_assignment_and_milestone
    Grade.update(@grade, {:score => 4.5})
    assert_in_delta @previous.earned + 4.5, Milestone.find(@previous).earned, 0.001
    assert_equal @previous.possible + @grade.point_value, Milestone.find(@previous).possible
  end

  def test_reject_nonnumerical_score_and_leave_marking_period
    @grade.expects(:change_marking_period).times(0)
    Grade.update(@grade, {:score => 'invalid'})
    assert_equal Grade::DEFAULT_SCORE, @grade.score
  end

  def test_removing_numerical_score_updates_marking_period
    stub_assignment_and_milestone
    point_value = @grade.point_value
    [point_value,'-'].each do |score|
      Grade.update(@grade, {:score => score})
      milestone = Milestone.find(@previous)
      assert_equal score.to_i, milestone.earned
      assert_equal score.to_i, milestone.possible
    end
  end

  def test_changing_numerical_score_changes_marking_period
    stub_assignment_and_milestone
    [5,10].each do |score|
      Grade.update(@grade, {:score => score})
      milestone = Milestone.find(@previous)
      assert_in_delta Grade.find(@grade).score.to_f, milestone.earned.to_f, 0.001
      assert_equal @grade.point_value, milestone.possible
    end
  end

  #def test_destroy_when_user_gone
  #  @student.destroy
  #  assert_equal [], @student.grades(true)
  #end goes in student test

  def test_destroy_grade_affects_milestone
    stub_assignment_and_milestone
    @grade.score = 5
    @grade.save
    @grade.destroy
    assert_in_delta @previous.earned, Milestone.find(@previous).earned.to_f, 0.001
  end

  def test_percent
    @grade = Grade.new(:score => 10)
    @grade.expects(:assignment).returns(stub(:point_value => 20))
    assert_equal 50.0, @grade.percent
  end

  def test_changing_assignment_point_value_alters_milestone
    set_milestones_and_update_assignment(10, 1)
    assert_equal 4, @previous.earned
    assert_equal 10, @previous.possible
    assert_equal 0, @next.earned
    assert_equal 0, @next.possible
  end

  def test_changing_assignment_marking_period_alters_milestone
    set_milestones_and_update_assignment(5, 2)
    assert_equal 0, @previous.earned
    assert_equal 0, @previous.possible
    assert_equal 4, @next.earned
    assert_equal 5, @next.possible
  end

  def test_updating_assignment_point_value_and_marking_period_alters_milestone
    set_milestones_and_update_assignment(10, 2)
    assert_equal 0, @previous.earned
    assert_equal 0, @previous.possible
    assert_equal 4, @next.earned
    assert_equal 10, @next.possible
  end

  protected
  def stub_assignment_and_milestone
    Grade.any_instance.expects(:assignment).at_least_once.returns(Assignment.new(:point_value => 10, :reported_grade_id => 1))
    @previous = Milestone.create(:reported_grade_id => 1, :rollbook_entry_id => 1, :earned => 0, :possible => 0)
  end

  def set_milestones_and_update_assignment(point_value, reported_grade_id)
    @grade = Grade.new(:score => 4, :rollbook_entry_id => 1)
    former = Milestone.create(:reported_grade_id => 1, :rollbook_entry_id => 1, :earned => 4, :possible => 5)
    latter = Milestone.create(:reported_grade_id => 2, :rollbook_entry_id => 1, :earned => 0, :possible => 0)
    from = Assignment.new(:point_value => point_value,
                          :reported_grade_id => reported_grade_id)
    from.expects(:point_value_was).returns 5
    from.stubs(:reported_grade_id_was).returns 1
    @grade.assignment_changes_marking_period(from)
    @previous, @next = Milestone.find(former), Milestone.find(latter)
  end
end

