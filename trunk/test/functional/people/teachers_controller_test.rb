require 'test_helper'

class People::TeachersControllerTest < ActionController::TestCase
  
  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns(true)
    @school.stubs(:teachers).returns(@teachers = [Teacher.new, Teacher.new])
  end

  def test_term_link_to_future
    stub_teachers
    @school.stubs(:terms).returns([term, Term.new])
    @school.stubs(:teacher_limit).returns(1)
    Section.stubs(:find).returns([])
    get :index
    assert_response :success
    assert_select 'a[href=?]', teachers_url(:term => 'future'), :text => 'next'
  end

  def test_term_link_to_current
    stub_teachers
    @school.stubs(:terms).returns([Term.new, term])
    @school.stubs(:teacher_limit).returns(1)
    get :index, :term => 'future'
    assert_select 'a[href=?]', teachers_url, :text => 'current'
  end
    
  def test_index_with_sections
    @school.stubs(:terms).returns([term])
    stub_sections
    @teacher.stubs(:to_param).returns 'id'
    get :index
    assert_select "a[title=?]", 'Click to see an overview of this Algebra class'
  end

  def test_index_in_future
    @school.stubs(:terms).returns([Term.new, term])
    stub_sections
    get :index, :term => 'future'
    assert_select "td", 'Prep'
  end

  def test_show
    stub_teacher
    @teacher.stub_path('sections.where.includes').returns [@section = Section.new]
    @section.stubs(:teacher).returns @teacher
    prep_mp
    get :show, :id => @teacher
    assert_response :success
  end

  def test_show_no_sections
    stub_teacher
    prep_mp
    get :show, :id => @teacher
    assert_response :success
  end

  def test_update
    stub_update
    put :update, :id => @teacher
    assert_redirected_to teacher_path(@teacher)
  end

  def test_update_and_reset
    stub_update
    put :update, :id => @teacher, :teacher => {:reauthorize => true}
    assert_redirected_to teacher_path(@teacher)
  end

  def test_update_fail
    stub_update(false)
    put :update, :id => @teacher
    assert_template('edit')
  end

  def test_logins
    stub_teacher
    @teacher.stubs(:id).returns(1)
    get :logins, :id => @teacher
    assert_response :success
  end

  def test_new
    get :new
    assert_response :success
  end

  def test_create
    @teachers.expects(:create).returns(@teacher = stub(:valid? => true, :full_name => 'name', :login => 'login'))
    @school.expects(:may_add_more_teachers?).returns true
    post :create, :teacher => {:authorization => {:login => 'login'}}
    assert_redirected_to edit_teaching_load_path(@teacher)
  end

  def test_create_fail
    @teachers.expects(:create).returns(@teacher = Teacher.new)
    post :create
    assert_template('new')
  end

  def test_cannot_destroy_self
    stub_teacher
    @user.stubs(:id).returns('same')
    @teacher.stubs(:id).returns('same')
    delete :destroy, :id => @teacher
    assert_redirected_to teacher_path(@teacher)
  end

  def test_destroy
    stub_teacher
    @user.stubs(:id).returns('not the same as teacher')
    @teacher.expects(:destroy).returns(true)
    delete :destroy, :id => @teacher
    assert_redirected_to teachers_path
  end

  def test_destroy_xhr
    stub_teacher
    @user.stubs(:id).returns('not the same as teacher')
    @teacher.expects(:destroy).returns(true)
    xhr :delete, :destroy, :id => @teacher
    #assert_redirected_to teachers_path should be a way to do this...
  end
  
  def test_destroy_fail
    stub_teacher
    @user.stubs(:id).returns('not the same as teacher')
    @teacher.expects(:destroy).returns(false)
    delete :destroy, :id => @teacher
    assert_redirected_to teacher_path(@teacher)
  end
  protected
  
  def stub_find
    @teachers.expects(:find).returns([@teacher = Teacher.new(:last_name => 'test')])
  end
  
  def stub_sections
    @school.stubs(:teachers).returns([teacher = Teacher.new])
    section = Section.new(:time => '1')
    Section.stub_path('where.includes.group_by').returns({nil => [section]})
    section.stubs(:subject).returns(Subject.new(:name => 'Algebra'))
    section.stubs(:teacher).returns @teacher
    @school.stubs(:teacher_limit).returns(1)
  end
  
  def stub_teacher
    @teachers.expects(:find).returns(@teacher = Teacher.new(:first_name => 'test', :last_name => 'name'))
    @teacher.stubs(:to_param).returns 'id'
  end

  def stub_teachers
    Teacher.any_instance.stubs(:display_name).returns 'name'
  end

  def stub_update(response = true)
    stub_teacher
    @teacher.expects(:update_attributes).returns(response)
    @teacher.expects(:display_name).returns('teacher') if response
  end

  def term
    Term.new(:low_period => 1, :high_period => 6)
  end

end
