require 'test_helper'

class Catalog::SubjectsControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = Fixtures.identify(:default)
    login_as :Sir
    Teacher.any_instance.stubs(:admin?).returns(true)
  end

  def test_fail_login
    [nil, 1].each do |user|
      @request.session[:user] = user
      @request.session[:school] = Fixtures.identify(:default)
      get :index, :department_id => 'dept'
      assert_redirected_to login_path
    end
  end

  def test_destroy
    prep_destroy
    delete :destroy, :department_id => @d, :id => @s
    assert_redirected_to :action => 'index'
    assert_raise(ActiveRecord::RecordNotFound) { Subject.find(@s) }
  end

  def test_destroy_xhr
    prep_destroy
    xhr :delete, :destroy, :department_id => @d, :id => @s
    #assert_select_rjs can't handle :remove yet
    assert_raise(ActiveRecord::RecordNotFound) { Subject.find(@s) }
  end

  def test_update
    put :update, :department_id => departments(:math), :id => subjects(:algebra), :subject => {:name => 'Algebra 1'}
    assert_redirected_to department_subject_url(assigns(:subject).department_id, assigns(:subject))
  end

  def test_update_fail
    put :update, :department_id => departments(:math), :id => subjects(:algebra_2), :subject => {:name => 'Algebra I'}
    assert_template('edit')
  end

  def test_show
    @controller.stubs(:prepare_section_data)
    get :show, :department_id => departments(:math), :id => subjects(:algebra)                                        
    assert_template('show')
  end

  def test_index
    get :index, :department_id => departments(:math)
    assert_template('index')
  end

  def test_edit
    get :edit, :department_id => departments(:math), :id => subjects(:algebra)
    assert_template('edit')
    assert assigns(:subject)
  end

  def test_create
    prep_create
    @subject.expects(:name).returns('subj')
    @department.expects(:name).returns('dept')
    post :create, :department_id => @department
    assert_redirected_to department_subjects_url(@department)
  end

  def test_fail_create
    prep_create(false)
    post :create, :department_id => @department
    assert_template('new')
  end

  protected
  def prep_create(success = true)
    School.any_instance.expects(:departments).returns(@departments = mock())
    @departments.stub_path('includes.find').returns(@department = Department.new)
    @department.stubs(:to_param).returns 'id'
    @department.stubs(:subjects).returns(@subjects = [])
    @subjects.expects(:create).returns(@subject = Subject.new)
    @subject.expects(:valid?).returns(success)
  end

  def prep_destroy
    @d = schools(:default).departments.create(:name => 'destroyable', :subjects_attributes => [:name => 'destroyable'])
    @s = @d.subjects.first
  end
end

