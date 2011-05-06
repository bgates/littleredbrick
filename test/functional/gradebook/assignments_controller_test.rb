require 'test_helper'

class Gradebook::AssignmentsControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns true
    Section.expects(:find).returns(@section = Section.new)
    @section.expects(:teacher).at_least_once.returns @user 
  end

  def test_index
    @section.expects(:marking_periods).returns([MarkingPeriod.new])
    @mp = MarkingPeriod.new(:reported_grade_id => 1)
    @section.expects(:current_marking_period).at_least_once.returns(@mp)
    Assignment.expects(:maximum).returns(1)
    get :index, :section_id => 1
    assert_template('index')
  end

  def test_show
    MarkingPeriod.expects(:find_by_track_id_and_reported_grade_id).returns(MarkingPeriod.new)
    stub_assignments(false, false)
    @assignments.expects(:find).with(1, :include => :grades).returns(@assignment)
    @assignment.attributes = {:date_due => Date.today, :date_assigned => Date.today + 1, :description => '', :position => 1}
    @assignments.expects(:near).returns([Assignment.new])
    get :show, :section_id => 1, :id => 1
    assert_template('show')
  end

  def test_new
    stub_new
    get :new, :section_id => 1
    assert_template('new')
  end

  def test_new_individual_due_dates_for_grades
    stub_new
    get :new, :section_id => 1, :due => 'individual'
    assert_template('new')
  end
  
  def test_create
    post_assignment(true)
    post :create, :section_id => 1, :assignment => {}
    assert flash[:notice]
    assert_redirected_to section_gradebook_path(@section)
  end

  def test_create_fail
    post_assignment(false)
    @assignment.errors.add(:date_due, 'error msg')
    stub_marking_periods
    post :create, :section_id => 1, :assignment => {}
    #assert_select '.fieldWithErrors'
    assert_template('new')
  end

  def test_destroy
    stub_assignments(true, false)
    @assignment.expects(:destroy).returns(true)
    post :destroy, :section_id => 1, :id => 1, :method => :delete
    assert flash[:notice]
    assert_redirected_to section_gradebook_path(@section)
  end

  def test_destroy_xhr
    stub_assignments(true, false)
    @assignment.expects(:destroy).returns(true)
    xhr :delete, :destroy, :section_id => 1, :id => 1
    assert flash[:notice]
    #don't rememember how to test redirect in js
  end
  
  def test_edit
    stub_assignments
    stub_marking_periods
    get :edit, :section_id => 1, :id => 1
    assert_response :success
  end

  def test_update_fail
    stub_assignments
    stub_marking_periods
    @assignment.expects(:update_attributes).returns(false)
    @assignment.errors.add(:date_due, 'error msg')
    post :update, :section_id => 1, :id => 1, :method => :put, :assignment => {}
    assert_template('edit')
    #assert_select '.fieldWithErrors'
  end

  def test_update
    @section.stubs(:assignments).returns(mock(:find => @assignment = Assignment.new))
    @assignment.expects(:update_attributes).returns(true)
    put :update, :section_id => 1, :id => 1, :assignment => {}
    assert_redirected_to section_gradebook_url(@section)
  end

  def test_fail_update_individual_grades
    stub_assignments
    stub_marking_periods
    @assignment.expects(:update_attributes).returns(false)
    @assignment.stub_path('grades.includes').returns([@grade = Grade.new])
    @grade.stubs(:id).returns(1)
    @grade.expects(:rollbook_entry).returns(mock(:student => Student.new))
    put :update, :section_id => 1, :assignment => {:grades => {'1' => {:date_due => 'filler'}}}, :id => 1
    assert_template('edit')
  end
  
  def test_performance_empty
    prep_performance
    get :performance, :section_id => 'test'
    assert_response :success
  end

  def test_performance
    prep_performance
    @assign1, @assign2 = Assignment.new, Assignment.new
    assignments = stub(:maximum => 10, :categories => ['tests'], :size => 2)
    assignments.stub_path('where.includes').returns [@assign1, @assign2]
    @section.stubs('assignments').returns assignments
    @rbe = RollbookEntry.new
    @rbe.expects(:student).at_least_once.returns(Student.new)
    @rbe.expects(:grade_for).at_least_once.returns('filler')
    @section.expects(:rollbook_entries).returns(stub(:includes => [@rbe]))
    get :performance, :section_id => 'test'
    assert_response :success
  end

protected

  def post_assignment(response)
    stub_assignments(false, false)
    @assignments.expects(:create).returns(@assignment)
    @assignment.expects(:valid?).returns(response)
  end

  def stub_assignments(single = true, double = true)
    @assignments = mock()
    @assignment = Assignment.new
    @section.stubs(:assignments).returns(@assignments)
    @assignments.expects(:find).with(1).returns(@assignment) if single
    @assignments.stubs('categories').returns ['category']
  end

  def stub_marking_periods
    @section.stub_path('track.marking_periods.includes').returns([MarkingPeriod.new])
  end

  def stub_new
    @section.expects(:current_marking_period).returns(MarkingPeriod.new)
    stub_assignments(false)
    @assignments.expects(:build).returns(Assignment.new(:date_due => Date.today))
    stub_marking_periods
  end

    def prep_performance
      @section.expects(:current_marking_period).returns(stub(:reported_grade_id => 1))
      @section.expects(:marking_periods).returns([stub(:position => 1)])
    end
end
