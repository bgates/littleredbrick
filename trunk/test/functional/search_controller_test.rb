require 'test_helper'

class SearchControllerTest < ActionController::TestCase
    
  def setup
    generic_setup Teacher
    @controller.stubs(:authorized?).returns(true)
    School.expects(:find).returns(@school)
    @term = Term.new(:low_period => 1, :high_period => 6)
    @school.stubs(:terms).returns [@term]
    @school.stubs(:current_term).returns(@term)
  end

  def test_index
    get :index
    assert_response :success
  end

  def test_simple_search
    @school.expects(:students).returns(@students = mock())
    @students.expects(:where).with(['users.grade IN (?)', 9]).returns(stub(:includes => [@student = Student.new(:first_name => 'test', :last_name => 'student')]))
    get :index, :grade => 9, :commit => 'search'
    assert_response :success
  end

  def test_full_search
    @school.expects(:students).returns(@students = mock())
    @students.expects(:where).with(['users.grade IN (?) AND departments.id IN (?) AND sections.time IN (?)', [9,10], [11, 12], [1,2,3]]).returns(proxy = stub)
    proxy.stubs(:includes).with([{:rollbook_entries => {:section => [:teacher, {:subject => :department}]}}]).returns([@student = Student.new(:first_name => 'test', :last_name => 'student')])
    @student.stubs(:rollbook_entries).returns([@rbe = stub(:section => @section = mock())])
    @section.expects(:name).returns('class')
    @section.expects(:time).returns(2)
    @section.expects(:name_and_time).returns('class (period 2)')
    @section.stubs(:teacher).returns(stub(:display_name => 'teacher'))
    get :index, :grade => [9, 10], :department => [11, 12], :period => [1,2,3], :commit => 'search'
    assert_response :success
  end
end
