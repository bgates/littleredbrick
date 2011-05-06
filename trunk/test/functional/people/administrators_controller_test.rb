require 'test_helper'

class People::AdministratorsControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns true
    @school.stub_path('admins.find').returns(@admin = Staffer.new(:last_name => 'test'))
    @admin.stubs(:to_param).returns 'id'
  end

  def test_fail_login
    @request.session[:school] = @request.session[:user] = :exists
    @user.expects(:admin?).returns(false)
    get :show, :id => @admin
    assert_redirected_to login_path
  end

  def test_index
    @school.stubs(:admins).returns([Staffer.new(:first_name => 'test', :last_name => 'name')])
    @school.stubs(:terms).returns [@term = Term.new]
    get :index
    assert_template('index')
  end

  def test_show
    get :show, :id => @admin
    assert_template('show')
  end

  def test_edit
    get :edit, :id => @admin
    assert_template('edit')
  end

  def test_create
    @school.stubs(:staffers).returns(stub(:create => (@admin = Staffer.new)))
    @admin.expects(:valid?).returns(true)
    post :create, :admin => {:first_name => 'test', :last_name => 'admin'}
    assert_redirected_to :action => 'index'
    assert flash[:notice]
  end

  def test_create_fail
    @school.stubs(:staffers).returns(stub(:create => (@admin = Staffer.new)))
    @admin.expects(:valid?).returns(false)
    post :create, :admin => {:first_name => 'test', :last_name => 'admin'}
    assert_template('new')
  end

  def test_destroy
    @admin.stubs(:id).returns('not current user')
    @admin.expects(:revoke_admin).returns(true)
    delete :destroy, :id => @admin
    assert flash[:notice]
    assert_redirected_to :action => 'index'
  end

  def test_cannot_self_destruct
    @admin.stubs(:id).returns('current user')
    @user.stubs(:id).returns('current user')
    delete :destroy, :id => @admin
    assert flash[:error]
    assert_redirected_to :action => 'index'
  end

  def test_fail_destroy
    @admin.stubs(:id).returns('not current user')
    @admin.expects(:revoke_admin).returns(false)
    delete :destroy, :id => @admin
    assert flash[:error]
    assert_redirected_to :action => 'index'
  end

  def test_new
    get :new
    assert_template('new')
  end

  def test_search
    Teacher.expects(:search).returns([Teacher.new])
    get :search
    assert_template('new')
  end

  def test_update
    @admin.expects(:update_attributes).returns(true)
    put :update, :id => @admin
    assert_redirected_to administrators_path
  end

  def test_fail_update
    @admin.expects(:update_attributes).returns(false)
    put :update, :id => @admin
    assert_template('edit')
  end
end
