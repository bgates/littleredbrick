require 'test_helper'

class StudentControllerTest < ActionController::TestCase

  def setup
    generic_setup Student
  end

  def test_index
    prep_index
    get :index
    assert_response :success
  end

  def test_parent_viewing_child
    prep_index
    @controller.stubs(:current_user).returns(@parent = Parent.new)
    @parent.children.stubs(:find).returns(@user)
    @user.first_name = 'test'
    get :index, {}, {:child => 1, :school => :exists, :user => :exists}  
    assert_response :success
  end
  
  def test_show
    @sections = [@section = Section.new]
    @sections.expects(:find).returns @section
    @user.stubs(:sections).returns @sections
    @user.expects(:rollbook_entries).returns(mock(:find_by_section_id => @rbe = RollbookEntry.new))
    @section.stubs(:teacher).returns(Teacher.new(:first_name => 'teacher', :last_name => 'test'))
    @section.stubs(:to_param).returns('section')
    @rbe.stubs(:milestones).returns(@milestones = stub(:includes => [@mark = Milestone.new(:reported_grade_id => 2)], :detect => @mark))
    Milestone.expects(:order).returns([@mark])
    @mark.expects(:reported_grade).returns(mock(:description => 'mp 1'))
    prep_mp
    get :show, :section_id => @section
    assert_response :success
  end

  def test_assignments
    prep_mp
    @user.stub_path('sections.find').returns @section = Section.new
    @section.stubs(:to_param).returns('section')
    @section.stubs(:current_marking_period).returns(stub(:reported_grade_id => 1))
    @section.stubs(:marking_periods).returns([MarkingPeriod.new])
    @user.stubs(:rollbook_entries).returns(stub(:find_by_section_id => @rbe = RollbookEntry.new))
    @grades = Array.new(2){Grade.new}
    @rbe.stub_path('grades.where.includes.sort_by').returns @grades
    @grades.each_with_index do |g, i| 
      g.stubs(:assignment).returns(stub(:position => i, :date_due => Date.today + i, :title => 'assignment', :to_param => i.to_s, :reported_grade_id => 2, :category => 'test', :point_value => 10))
    end
    get :assignments, :section_id => @section
    assert_response :success
  end

  def test_assignment
    @user.stub_path('sections.find').returns @section = Section.new
    @section.stubs(:assignments).returns(@assignments = mock())
    @rbe.stubs(:id).returns(3)
    @assignment = stub(:category => 'test', :reported_grade_id => 1, :position => 4, :date_due => Date.today, :score => 5, :title => 'Test', :point_value => 100, :to_param => 'id', :date_assigned => Date.today - 1, :description => '', :reported_grade => stub(:description => 'marking period 1'))
    @assignment.stubs(:marking_period_number).returns 1
    @assignments.stub_path('find.joins.select').returns @assignment
    @section.stubs(:id).returns(2)
    @assignments.expects(:category_points).with('test', 1).returns 50
    @assignments.expects(:marking_period_points).with(1).returns 100
    @assignments.stub_path('where.order').returns([@other = Assignment.new, @assignment])
    @other.stubs(:to_param).returns('other id')
    get :assignment, :section_id => @section, :assignment_id => 'id'
    assert_response :success
  end

  def test_only_student_or_parent_can_see
    @controller.stubs(:current_user).returns(Teacher.new)
    get :index
    assert_redirected_to login_path
  end
  
  protected
  def prep_index
    @user.stub_path('rollbook_entries.where.includes.sort_by').returns [@rbe = RollbookEntry.new]
    @rbe.stubs(:section).returns(@section = Section.new(:time => 1))
    @section.stubs(:name).returns('class')
    @section.stubs(:to_param).returns('section')
    @rbe.expects(:milestones).returns([Milestone.new(:reported_grade_id => 2)])
    prep_mp
  end
end
