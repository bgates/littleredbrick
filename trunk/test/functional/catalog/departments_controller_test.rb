require 'test_helper'

class Catalog::DepartmentsControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = Fixtures.identify(:default)
    login_as :Sir
    Teacher.any_instance.stubs(:admin?).returns(true)
  end

  def test_fail_login
    [nil,1].each do |user|
      @request.session[:user] = user
      get :index
      assert_redirected_to login_path
    end
  end

  def test_full_index
    School.any_instance.stubs(:terms).returns([stub(:to_param => 'id')])
    get :index
    assert_template 'index'
  end

  def test_new
    get :new
    assert assigns(:department).is_a?(Department)
  end

  def test_new_xhr
    xhr :get, :new
    assert_select_rjs
  end

  def test_create
    post :create, :department => {:name => 'new', :subjects_attributes => [{:name => 'first'}, { :name => 'second'}]}
    @d = assigns(:department)
    assert @d.valid?
    assert_equal 'new', @d.name
    assert_equal 2, @d.subjects.size
    assert_redirected_to departments_url
  end

  def test_create_xhr
    xhr :post, :create, :department => {:name => 'new', :subjects_attributes => [{:name => 'first'}, { :name => 'second'}]}
    assert assigns(:department).valid?
    assert_select_rjs
  end

  def test_destroy
    @school = schools(:default)
    @d = @school.departments.create(:name => 'fuck this', :subjects_attributes => [{:name => 'shit'}])
    delete :destroy, :id => @d
    assert_redirected_to departments_url
    #assert_raise(ActiveRecord::RecordNotFound) { Department.find(@d) }
  end

  def test_destroy_xhr
    xhr :delete, :destroy, :id => departments(:math).id
    assert_response :success
  end

  def test_fail_destroy
    Department.any_instance.expects(:destroy).returns(false)
    delete :destroy, :id => departments(:math).id
    assert_redirected_to departments_path
  end

  def test_fail_destroy_xhr
    Department.any_instance.expects(:destroy).returns(false)
    xhr :delete, :destroy, :id => departments(:math).id
    assert_response :success
  end

  def test_edit
    department = departments(:math)
    algebra = subjects(:algebra)
    algebra2 = subjects(:algebra_2)
    original_name = algebra.name
    put :update, :id => department.id, :department => {:name => 'mathematics', :subjects_attributes => {algebra2.id.to_s => {:name => 'Algebra 2'}, algebra.id.to_s => {:name => ''}, Time.now.to_i => {:name => 'tensor analysis'}}}
    assert_redirected_to department_subjects_url(department)
    @department = Department.find(department)
    assert_equal 'mathematics', @department.name
    assert_equal Subject.find_by_name('tensor analysis').department_id, @department.id
    assert_equal original_name, Subject.find(algebra).name
  end

  def test_fail_edit
    department = departments(:math)
    put :update, :id => department.id, :department => {:name => ''}, :subjects_attributes => {:name => 'tensor analysis'}
    assert_template('edit')
    @department = Department.find(department)
    assert_equal department.name, @department.name
    assert_nil @department.subjects.find_by_name('tensor analysis')
  end

  def test_get_edit
    department = departments(:math)
    get :edit, :id => department.id
    assert_template('edit')
  end

end

