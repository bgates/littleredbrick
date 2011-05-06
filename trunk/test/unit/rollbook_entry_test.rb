require 'test_helper'

class RollbookEntryTest < ActiveSupport::TestCase

  def test_bulk_import
    @sections = Array.new(2){|n| Section.new}
    @rbes = Array.new(2){|n| RollbookEntry.new}
    @sections.each_with_index do |s, i|
      s.stubs(:id).returns(i + 1)
      @rbes[i].section_id = i + 1
    end
    @sections.first.expects(:assignments).returns([stub(:id => 'assignment 1'), stub(:id => 'assignment 2')])
    @term = mock(:reported_grades => [stub(:id => 'term reported grade')])
    @sections.first.expects(:term).returns(@term)
    RollbookEntry.expects(:where).with(['section_id IN (?)', [1,2]]).returns(stub(:includes => @rbes))
    Milestone.expects(:import)
    Grade.expects(:import).returns(true)
    assert RollbookEntry.bulk_grades_and_milestones_for(@sections)
  end

  def test_rollbook_entry_shortcuts
    @student = Student.new(:first_name => 'Doc', :last_name => 'Holliday', :id_number => 100)
    @rbe = RollbookEntry.new
    @rbe.expects(:student).times(3).returns(@student)
    [:first_name, :last_name, :id_number].each do |attr|
      assert_equal @rbe.send(attr), @student.send(attr)
    end
  end

  def test_grades_created_on_enrollment
    prep(true)
    Milestone.expects(:setup).returns(true)
    Section.any_instance.expects(:assignments).returns(Array.new(5, Assignment.new))
    Assignment.any_instance.expects(:default_grade_for).times(5)
    @section.enroll(@student)
  end

  def test_unenroll_student
    prep
    @section.unenroll(@student)
    assert !@student.sections(true).include?(@section)
    assert !@section.students.include?(@student)
    assert_equal nil, RollbookEntry.find_by_student_id(@student)
  end

  def test_grades_destroyed_when_student_removed_from_class
    prep
    @assignment = @section.assignments.create(:title => 'What I programmed over summer vacation', :category => 'test', :point_value => 5, :date_assigned => Date.today, :date_due => Date.today.succ, :reported_grade_id => 1)
    @section.unenroll(@student)
    assert_equal nil, @student.grades(true).detect{|g| g.assignment_id == @assignment.id}
  end

  def test_destroy_section
    prep
    rbe = RollbookEntry.find_by_student_id_and_section_id(@student, @section)
    @section.destroy
    assert_raise(ActiveRecord::RecordNotFound) { RollbookEntry.find(rbe) }
  end

  def test_destroy_student
    prep
    rbe = RollbookEntry.find_by_student_id_and_section_id(@student, @section)
    @student.destroy
    assert_raise(ActiveRecord::RecordNotFound) { RollbookEntry.find(rbe) }
  end

  def test_categorization
    run_category_test
  end

  def test_categorization_with_ungraded_category
    run_category_test(true)
  end

  def test_empty_grade_progression
    progression_setup(0)
    grade = Grade.new
    assert_equal [], @rbe.grade_progression([])
    assert_equal [], @rbe.grade_progression([grade])
  end

  def test_no_graded_grade_progression
    @rbe = RollbookEntry.new
    @milestone = Milestone.new(:earned => 0, :possible => 0)
    @rbe.stubs(:milestones).returns([@milestone])
    assert_equal [], @rbe.grade_progression([Grade.new])
  end

  def test_grade_for_range
    @rbe = RollbookEntry.new
    @rbe.expects(:id).at_least_once.returns(1)
    grades1, grades2, grades3, grades4, assignments = [], [], [], [], []
    [[47, true, 7], [59, true, 8], [1, true, 9]].each do |id, graded, score|
      grades1 << stub(:rollbook_entry_id => id, :graded? => graded, :score => score)
    end
    [[47, false, nil], [59, false, nil], [1, true, 72]].each do |id, graded, score|
      grades2 << stub(:rollbook_entry_id => id, :graded? => graded, :score => score)
    end
    [[47, true, 17], [59, true, 28], [1, false, nil]].each do |id, graded, score|
      grades3 << stub(:rollbook_entry_id => id, :graded? => graded, :score => score)
    end
    [[47, true, 37], [59, true, 48], [1, true, 39]].each do |id, graded, score|
      grades4 << stub(:rollbook_entry_id => id, :graded? => graded, :score => score)
    end
    [[grades1, 10], [grades2, 100], [grades3, 30], [grades4, 50]].each do |grade_range, points|
      assignments << stub(:grades => grade_range, :point_value => points)
    end
    @response = {:earned => 120, :possible => 160, :percent => 75.0}
    assert_equal({}, @rbe.grade_for(assignments).diff(@response))
  end

  def test_grade_progression
    progression_setup(100)
    @milestone.expects(:grade).returns(80)
    g1 = stub(:graded? => true, :score => 5, :point_value => 5, :due => Date.today + 6)
    g2 = stub(:graded? => true, :score => 18, :point_value => 25, :due => Date.today + 7)
    g3 = stub(:graded? => false)
    g4 = stub(:graded? => true, :score => 39, :point_value => 50, :due => Date.today + 9, :assignment => stub(:reported_grade_id => 500))
    @response = [{:position => 0, :grade => 90.0, :description => g1.due.strftime("%b %d")}, {:position => 1, :grade => 92.0, :description => g2.due.strftime("%b %d")}, {:position => 2, :grade => 82.0, :description => g4.due.strftime("%b %d")}, {:position => 'current', :grade => 80}]
    assert_equal @response, @rbe.grade_progression([g1, g2, g3, g4])
  end

  def test_sort_milestones
    @rbe = RollbookEntry.new
    @milestones = Array.new(4) { |n| Milestone.new }
    @milestones.each_with_index do |m, i|
      m.stubs(:reported_grade).returns(i)
    end
    @rbe.stub_path('milestones.includes').returns(@milestones)
    ReportedGrade.expects(:sort).with([0, 1, 2, 3]).returns([3, 2, 1, 0])
    assert_equal(@milestones.reverse, @rbe.sort_milestones)
  end

  protected
    def progression_setup(possible)
      @rbe = RollbookEntry.new
      @milestone = Milestone.new(:earned => 80, :possible => possible)
      @rbe.stubs(:milestones).returns(stub(:detect => @milestone))
    end

    def run_category_test(use_ungraded_assignment = false)
      @rbe = RollbookEntry.new
      grades = []
      [[5, 10, 'homework'], [88, 100, 'test'], [7, 10, 'homework'], [0, 5, 'classwork']].each do |a, b, c|
        grades << stub(:graded? => true, :score => a, :point_value => b, :assignment => stub(:category => c))
      end
      grades << stub(:graded? => false, :assignment => stub(:category => 'dance')) if use_ungraded_assignment
      @response = {'homework' => {:earned => 12.0, :possible => 20},
                  'test' => {:earned => 88.0, :possible => 100},
                  'classwork' => {:earned => 0.0, :possible => 5}}
      assert_equal({}, @rbe.categorized_performance(grades).to_hash.diff(@response))
    end

    def prep(skip_enroll = false)
      Student.any_instance.stubs(:school).returns(School.new) 
      @student = Student.create(:first_name => 'test', :last_name => 'test', :school_id => 1)
      @section = Section.create(:subject_id => 1, :teacher_id => 1, :current => true, :track_id => 1)
      unless skip_enroll
        RollbookEntry.any_instance.expects(:set_grades_and_milestones).returns(true)
        @section.enroll(@student)
      end
  end

end

