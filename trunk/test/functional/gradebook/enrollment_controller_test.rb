require 'test_helper'

class Gradebook::EnrollmentControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    Section.stubs(:find).returns(@section = Section.new)
    @section.stubs(:teacher).returns(@user)
    @section.stubs(:to_param).returns 'id'
    @user.stubs(:display_name).returns 'mr teacher'
    @section.stubs(:belongs_to?).returns true
  end

  def test_fail_login
    @controller.stubs(:authorized?).returns(false)
    get :new, {:section_id => @section}, {:school => :exists, :user => :exists}
    assert_redirected_to login_path
  end

  def test_create
    @section.expects(:enroll).returns(true)
    @school.stub_path('students.find_by_id').returns @student = Student.new
    @student.stubs(:full_name).returns 'student name'
    post :create, :section_id => @section, :id => 'student'
    assert_redirected_to new_section_enrollment_url(@section)
  end

  def test_create_fail
    @section.expects(:name).at_least_once.returns('test name')
    @request.session[:return_to] = 'test location'
    post :create, :section_id => 'test', :id => 404
    assert_template('new')
    assert_select 'div#error'
  end

  def test_create_xhr
    @section.expects(:enroll).returns(true)
    School.any_instance.expects(:students).returns(mock(:find_by_id => mock(:full_name => 'student name')))
    xhr :post, :create, :section_id => 1
    assert_response :success
  end

  def test_destroy
    prep_destroy
    delete :destroy, :section_id => @section, :id => 'id'
    assert assigns(:teacher)
    assert_redirected_to section_path(sections(:section))
  end

  def test_destroy_xhr
    prep_destroy
    xhr :delete, :destroy, :section_id => @section, :id => 'id'
    assert_response :success
  end

  def test_search
    Student.expects(:search).returns([Student.new])
    @request.session[:return_to] = '/back'
    get :search, :section_id => @section
    assert_template('new')
  end

  def test_mass_enroll
    @section.expects(:bulk_enroll).returns(['a student', 'another student'])
    post :create, :names => 'a student\r\nanother student', :section_id => @section
    assert_redirected_to new_section_enrollment_path(@section)
  end

  def test_mass_enroll_fails
    @section.expects(:bulk_enroll).returns([])
    post :create, :names => 'nonexistent', :section_id => @section
    assert flash[:error]
    assert_redirected_to new_section_enrollment_path(@section)
  end

  def test_mass_enroll_partial_success
    @section.expects(:bulk_enroll).returns(['a student'])
    post :create, :names => "a student\nanother student", :section_id => @section
    assert_redirected_to new_section_enrollment_path(@section)
  end

  protected

    def prep_destroy
      @section.stub_path('students.find').returns @student = Student.new
      @student.stubs(:full_name).returns 'student name'
      @section.expects(:unenroll)
    end

end

