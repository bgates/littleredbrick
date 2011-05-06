require 'test_helper'

class Gradebook::GradebookControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @teacher = @user
    sections = [Section.new]
    @teacher.stubs(:sections).returns(sections)
    sections.stubs(:find_by_id).returns(@section = Section.new)
    @section.stubs(:to_param).returns 'id'
  end

  def test_prevent_unauthorized_entry
    @controller.expects(:authorized?).returns(false)
    get :show, :section_id => @section
    assert_redirected_to login_path
  end

  def test_empty_gradebook
    get :show, :section_id => 'empty'
    assert_equal [], assigns(:students)
    assert_template('show')
    assert_select 'img[alt="Remove Student"]', 0
  end

  def test_show
    @section.assignments.stubs(:find).returns([Assignment.new(:date_due => Date.today, :position => 1, :reported_grade_id => 1), Assignment.new(:date_due => Date.today + 5, :position => 2, :reported_grade_id => 2)])
    get :show, :section_id => @section
    assert_template('show')
  end

  def test_show_with_errors
    get :show, {:section_id => @section}, {}, {:bad_grades => [3,4,5]}
  end

  def test_case_name
    @section.stubs(:teacher).returns @user
    get :sort, :section_id => @section
    assert_template 'sort'
  end

  def test_sort
    @section.expects(:sort_by)
    post :sort, :section_id => @section
    assert_redirected_to section_gradebook_url(@section)
  end

  def test_post_no_errors
    post :update, :section_id => @section, :grade => {}, :method => :put
    assert_select 'div[id = "errorExplanation"]', 0
    assert flash[:error]
  end

  def test_post_all_valid
    @gradebook = stub(:valid? => true, :update => true)
    @controller.instance_variable_set(:@gradebook, @gradebook)
    @controller.instance_variable_set(:@all_assignments, Array.new(2))
    @controller.expects(:setup)
    post :update, :section_id => @section, :grade => 'valid', :method => :put
    assert flash[:notice]
    assert_redirected_to section_gradebook_path(@section)
  end

  def test_post_some_invalid
    assignment = [Assignment.new(:position => 1, :date_due => Date.today, :point_value => 10, :title => 'param')]
    assignment.stubs(:id).returns 1
    @gradebook = stub(:assignments => assignment,
                      :start => 0, :update => true, :valid? => false,
                      :grades => [], :set_milestones => [],
                      :set_range => [], :set_grades => [],
                      :month_and_year => [Date.today.year, Date.today.mon],
                      :spans_marking_periods? => false)
    Gradebook.expects(:new).returns(@gradebook)
    @section.expects(:rollbook_entries).returns([])
    post :update, :section_id => @section, :grade => 'invalid', :method => :put
    assert_select '#error>h2', 'Bad News'
    assert_template('show')
  end

end

