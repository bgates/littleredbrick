require 'test_helper'

class GradebookTest < Test::Unit::TestCase

  def setup
    @section = Section.new
  end

  def test_create_with_start_param
    stub_section(['position >= ?', 6])
    @gradebook = Gradebook.new(@section, {:start => 6})
  end

  def test_create_with_date_param
    stub_section(['date_due >= ?', Date.today])
    @gradebook = Gradebook.new(@section, {:date => Date.today})
  end

  def test_create_with_marking_period_param
    stub_section(['reported_grade_id = ?', 3])
    @gradebook = Gradebook.new(@section, {:marking_period => 3})
  end

  def test_create
    stub_section
    @gradebook = Gradebook.new(@section)
    assert_equal 0, @gradebook.start
    assert_equal [], @gradebook.set_milestones
  end

  def test_set_grades
    rbe1, rbe2 = stub(:id => 1, :student_id => 10), stub(:id => 2, :student_id => 20), stub(:id => 3, :student_id => 30)
    grade1_1, grade2_1, grade1_2, grade2_2 = stub(:rollbook_entry_id => 1),
                                             stub(:rollbook_entry_id => 2),
                                             stub(:rollbook_entry_id => 1),
                                             stub(:rollbook_entry_id => 2)
    @section.expects(:rollbook_entries).returns([rbe1, rbe2])
    @gradebook = Gradebook.new(@section)
    @gradebook.expects(:section_grades).returns([grade1_1, grade2_1, grade1_2, grade2_2])
    assert_equal({}, @gradebook.grades)
    @expected_response = {10 => [grade1_1, grade1_2], 20 => [grade2_1, grade2_2], 30 => []}
    assert_equal @expected_response.diff(@gradebook.set_grades), {}
    assert_equal @expected_response.diff(@gradebook.grades), {}
  end

  def test_check_validity
    @gradebook = Gradebook.new(@section)
    @gradebook.update({})
    assert @gradebook.valid?
  end

  def test_delete_grades_before_update
    @gradebook = Gradebook.new(@section)
    @gradebook.expects(:section_grades).times(3).returns([stub(:id => 1, :score => '-'), stub(:id => 2, :score => '-'), stub(:id => 5, :score => '-')])
    Grade.expects(:update).with(['2'], [:score => 10]).returns([stub(:id => 2, :valid? => true)]) #the only changed grade
    @gradebook.expects(:set_grades)
    @gradebook.update(
      '1' => {:score => '-'}, '2' => {:score => 10}, '5' => {:score => '-'}
    )
    assert @gradebook.valid?
  end

  def test_set_milestones
    @assignments = [stub(:reported_grade_id => 7, :position => 1, :grades => [])]
    @section.stub_path('assignments.limit.order.includes').returns(@assignments)
    @gradebook = Gradebook.new(@section)
    @section.expects(:milestones).returns(@milestones = mock())
    m1 = stub(:rollbook_entry_id => 100, :grade => '-')
    m2 = stub(:rollbook_entry_id => 200, :grade => 100)
    @milestones.expects(:find_all_by_reported_grade_id).with(7).returns([m1, m2])
    rbe1, rbe2 = stub(:id => 100, :student_id => 1), stub(:id => 200, :student_id => 2)
    @section.expects(:rollbook_entries).returns([rbe1, rbe2])
    @gradebook.set_milestones
    assert_equal({1 => '-', 2 => 100}, @gradebook.milestones)
  end

  def test_range_grades
    a1, a2, a3 = stub(:point_value => 5, :id => 100, :position => 1, :grades => nil),
                 stub(:point_value => 100, :id => 200, :position => 2, :grades => nil),
                 stub(:point_value => 20, :id => 300, :position => 3, :grades => nil)
    @section.stub_path('assignments.limit.order.includes').returns([a1, a2, a3])
    @gradebook = Gradebook.new(@section)
    g1_1 = stub(:graded? => true, :score => 5, :assignment_id => a1.id)
    g1_2 = stub(:graded? => false)
    g1_3 = stub(:graded? => true, :score => 10, :assignment_id => a3.id)

    g2_1 = stub(:graded? => true, :score => 5, :assignment_id => a1.id)
    g2_2 = stub(:graded? => true, :score => 100, :assignment_id => a2.id)
    g2_3 = stub(:graded? => true, :score => 20, :assignment_id => a3.id)

    g3_1 = stub(:graded? => true, :score => 4.5, :assignment_id => a1.id)
    g3_2 = stub(:graded? => false)
    g3_3 = stub(:graded? => false)
    grades = {1 => [g1_1, g1_2, g1_3], 2 => [g2_1, g2_2, g2_3], 3 => [g3_1, g3_2, g3_3], 4 => []}
    @gradebook.expects(:grades).returns(grades)
    assert_equal({1 => 60.0, 2 => 100.0, 3 => 90.0, 4 => '-'}, @gradebook.set_range)
  end

  def test_date
    @gradebook = Gradebook.new(@section)
    assert_equal [Date.today.year, Date.today.mon], @gradebook.month_and_year
  end

  def test_date_if_assignment_has_due_date
    @gradebook = Gradebook.new(@section)
    @due = Date.today + 10
    @gradebook.stubs(:assignments).returns([Assignment.new, Assignment.new(:date_due => @due)])
    assert_equal [@due.year, @due.mon], @gradebook.month_and_year
  end

  def test_date_if_individual_due_dates
    @gradebook = Gradebook.new(@section)
    @assignment = Assignment.new
    @assignment.expects(:grades).returns([stub(:date_due => Date.today), stub(:date_due => Date.today + 5), stub(:date_due => Date.today - 10)])
    @gradebook.stubs(:assignments).returns([Assignment.new(:date_due => Date.today), @assignment])
    assert_equal [(Date.today + 5).year, (Date.today + 5).mon], @gradebook.month_and_year
  end

  def test_invalid
    Grade.stubs(:set_default_score).returns true
    grade11 = Grade.new(:score => 5)
    grade12 = Grade.new(:score => 10)
    grade21 = Grade.new(:score => 10)
    grade22 = Grade.new(:score => 10) 
    grade_post_1 = Grade.new(:score => 10)
    grade_post_invalid = Grade.create
    grade_post_invalid.score = 'invalid'
    grade_post_invalid.valid?
    [grade11, grade12, grade21, grade22].each_with_index do |grade, i|
      grade.stubs(:id).returns i + 1
    end
    grades1 = [grade11, grade12]
    grades2 = [grade21, grade22]
    assign1 = stub(:position => 1, :grades => grades1)
    assign2 = stub(:grades => grades2)
    @assignments = [assign1, assign2]
    @section.stub_path('assignments.limit.order.includes').returns @assignments    
    Grade.expects(:update).with(['1','3'], [{:score => 10}, {:score => 'invalid'}]).returns([grade_post_1, grade_post_invalid])

    @gradebook = Gradebook.new(@section)
    assert_equal(@gradebook.section_grades, [grades1, grades2].flatten)
    @gradebook.update('1' => {:score => 10}, '2' => {:score => 10}, '3' => {:score => 'invalid'}, '4' => {:score => 10})
    assert !@gradebook.valid?
  end

  protected

    def stub_section(conditions = {})
      @assignments = []
      @section.stub_path('assignments.limit.order.includes').returns(@assignments)
      if !conditions.empty?
        @assignments.expects(:where).with(conditions).returns(@assignments)
      end
    end
end

