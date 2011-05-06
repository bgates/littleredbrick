require 'test_helper'

class MilestoneTest < ActiveSupport::TestCase

  def test_setup
    @section = Section.new
    @section.expects(:reported_grades).returns([stub(:id => 1), stub(:id => 2)])
    @section.stub_path('term.reported_grades').returns([stub(:id => 3), stub(:id => 4)])
    @milestones = mock
    @milestones.expects(:create).times(4).with{ |params| params[:reported_grade_id] < 5}
    @rbe = stub(:milestones => @milestones)
    Milestone.setup(@section, @rbe)
  end

  def test_grade
    @graded = Milestone.new(:earned => 78, :possible => 80.0)
    assert_in_delta @graded.grade, 100.0 * @graded.earned / @graded.possible, 0.001
    assert_in_delta @graded.calculate, 100.0 * @graded.earned / @graded.possible, 0.001
  end

  def test_not_graded
    @ungraded = Milestone.new(:earned => 78, :possible => 0.0)
    assert_equal '-', @ungraded.grade
  end

  def test_average
    prepare_predecessors
    @milestone.average_of([@p1, @p2])
    @average = Milestone.find(@milestone)
    assert_equal 100, @average.possible
    assert_in_delta 85, @average.earned, 0.001
  end

  def test_fail_average
    prepare_predecessors
    @p2.possible = 0
    @milestone.average_of([@p1, @p2])
    assert !@milestone.errors[:base].empty?
    assert_equal 0, @milestone.earned
    assert_equal 0, @milestone.possible
  end

  def test_reset
    @milestone = Milestone.new
    g1 = stub(:graded? => true, :score => 8, :point_value => 10)
    g2 = stub(:graded? => true, :score => 50, :point_value => 50)
    g3 = stub(:graded? => false)
    g4 = stub(:graded? => true, :score => 10, :point_value => 20)
    array = [g1, g2, g3, g4]
    rbe = stub(:grades => stub(:where => (stub(:includes => array))))
    @milestone.expects(:rollbook_entry).returns(rbe)
    @milestone.reset!
    @reset = Milestone.find(@milestone)
    assert_equal 80, @reset.possible
    assert_in_delta 68, @reset.earned, 0.001
  end

  def test_weight
    prepare_predecessors
    @milestone.weight_by([@p1, @p2], {'1' => 90, '2' => 10})
    @weighted = Milestone.find(@milestone)
    assert_equal 100, @weighted.possible
    assert_in_delta 81, @weighted.earned, 0.001
  end

  def test_combine
    prepare_predecessors
    @milestone.combine([@p1, @p2])
    @combined = Milestone.find(@milestone)
    assert_equal 300, @combined.possible
    assert_in_delta 260, @combined.earned, 0.001
  end

  def test_class_rank
    @milestone = Milestone.new
    @milestone.expects(:grade).returns(90)
    milestones = [@milestone]
    [60, 70, 80, 100].each{ |n| milestones << mock(:grade => n) }
    @milestone.expects(:class_milestones).returns(milestones)
    assert_equal 2, @milestone.class_rank
  end

  protected
  def prepare_predecessors
    @p1 = Milestone.new(:earned => 80, :possible => 100, :reported_grade_id => 1)
    @p2 = Milestone.new(:earned => 180, :possible => 200, :reported_grade_id => 2)
    @milestone = Milestone.create(:earned => 0, :possible => 0)
  end

end

