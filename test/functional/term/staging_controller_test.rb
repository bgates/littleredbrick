require 'test_helper'

class Term::StagingControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @teacher = @user
    @school.stub_path('terms.find').returns @term = Term.new
    @term.stubs(:to_param).returns 'term'
  end

  def test_show
    @controller.expects(:find_sections).returns([@section = Section.new(:time => 1)])
    @section.stubs(:teacher).returns(stub(:display_name => 'teacher'))
    get :show, :term_id => @term
    assert_response :success
  end

  def test_create_from_id
    stub_create
    @school.expects(:teachers).returns(mock(:find => @teacher = Teacher.new))
    @students.expects(:find).with('1').returns(@student = Student.new)
    post :create, :term_id => @term, :id => '1', :teacher => 'teacher'
    assert_redirected_to term_staging_path(@term, :teacher => 'teacher')
  end

  def test_create_from_name
    stub_create
    @students.expects(:find_by_full_name).with('name').returns(@student = Student.new)
    post :create, :term_id => @term, :search => 'name', :subject => 'class'
    assert_redirected_to term_staging_path(@term, :subject => 'class')
  end

  def test_create_xhr
    Section.stub_path('find.includes').returns(@section = Section.new)
    @school.teachers.expects(:find).returns(@teacher = Teacher.new)
    #@school.students.expects(:find).returns(@student = Student.new)
    @school.expects(:students).returns(mock(:find => Student.new))
    xhr :post, :create, :term_id => @term, :id => '1', :teacher => 'teacher'
    assert_response :success
  end
  
  def test_destroy
    Section.expects(:find).with('1').returns(@section = Section.new)
    @section.expects(:students).returns(mock(:find_by_full_name => @student = Student.new(:first_name => 'test', :last_name => 'name')))
    @section.expects(:unenroll).with(@student)
    @school.expects(:teachers).returns(mock(:find => @teacher = Teacher.new))
    delete :destroy, :term_id => @term, :section => '1', :name => 'test name', :teacher => 'teacher'
    assert_redirected_to term_staging_path(@term, :teacher => 'teacher')
  end

  def test_fail_destroy
    Section.expects(:find).with('1').returns(@section = Section.new)
    @school.expects(:teachers).returns(mock(:find => @teacher = Teacher.new))
    delete :destroy, :term_id => @term, :section => '1', :name => 'test name', :teacher => 'teacher'
    assert_redirected_to term_staging_path(@term, :teacher => 'teacher')
  end
  
  def test_search
    Student.expects(:search).returns([Student.new])
    xhr :get, :search, :term_id => @term, :section => 'class', :search => 'test name', :subject => 'class'
    assert_response :success
  end

  def test_department_no_sections
    @controller.expects(:find_sections).returns([])
    Subject.stubs(:find).returns(@subject = Subject.new(:name => 'subject'))
    @subject.expects(:department).returns(@dept = Department.new)
    @dept.stubs(:to_param).returns 'id'
    @user.stubs(:admin?).returns true
    get :show, :term_id => @term, :subject => 'subject'
    assert_response :success
  end

  def test_department_with_sections
    @controller.expects(:find_sections).returns([@section = Section.new])
    @section.stubs(:subject).returns(stub(:name => 'subject', :department => stub(:name => 'dept')))
    @section.stubs(:teacher).returns(Teacher.new(:first_name => 'test', :last_name => 'name'))
    @user.stubs(:admin?).returns true
    get :show, :term_id => @term, :subject => 'subject'
    assert_response :success
  end

  def test_find_sections_for_teacher
    @school.expects(:teachers).returns(mock(:find => @teacher))
    @teacher.stubs(:display_name).returns('teacher name')
    Section.stub_path('where.includes').returns([@section = Section.new])
    get :show, :term_id => @term, :teacher => 'teacher'
    assert_response :success
  end

  def test_find_sections_for_student
    @school.expects(:students).returns(mock(:find_by_id => @student = Student.new))
    @student.stubs(:to_param).returns 'id'
    get :show, :term_id => @term, :student => 'student'
    assert_response :success
  end
  protected
  def stub_create
    @school.expects(:students).returns(@students = mock())
    Section.stub_path('find.includes').returns(@section = Section.new)
    @section.expects(:teacher).returns(mock(:display_name => 'teacher'))
    @section.expects(:name).returns('section')
  end
end
