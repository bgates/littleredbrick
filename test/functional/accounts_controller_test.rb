require 'test_helper'

class AccountsControllerTest < ActionController::TestCase

  def setup
    generic_setup
  end

  def test_edit_as_parent
    generic_setup Parent
    @user.expects(:children).at_least_once.returns([])
    @user.expects(:gender).at_least_once.returns('father')
    get :edit, nil, {:school => :exists, :user => :exists}, {:show_initial_layout => true}
  end

  def test_edit_first_time
    get :edit, nil, {:school => :exists, :user => :exists}, {:show_initial_layout => true}
    assert_response :success
    assert_equal assigns(:first), true
  end

  def test_edit_second_time
    @controller.expects(:by_user).returns('teacher')
    get :edit
    assert_response :success
    assert_equal assigns(:first), nil
    assert_equal assigns(:school), @school
  end

  def test_forgot_password
    get :forgot_password
    assert_response :success
  end

  def test_reset_password
    @school.users.expects(:find_by_email).with('test').returns(@user)
    UserNotifier.stub_path('password_bypass.deliver')
    School.expects(:find).returns @school
    post :reset_password, :email => 'test'
    assert_redirected_to login_url
  end

  def test_reset_password_fails
    School.expects(:find).returns @school
    post :reset_password, :email => 'fail'
    assert_template('forgot_password')
  end

  def test_update
    @user.expects(:update_attributes).returns(@user)
    put:update
    assert_redirected_to home_url
  end

  def test_update_fail
    @user.expects(:update_attributes).returns(false)
    @controller.expects(:by_user).returns('teacher')
    post :update, :method => :put
    assert_template('edit')
  end

  def test_update_parent
    @user.expects(:has_invalid_children?).returns false
    @user.expects(:update_attributes).returns(@user)
    post :update, :method => :put
    assert_redirected_to home_url
  end

  def test_update_parent_fail
    generic_setup Parent
    @user.expects(:has_invalid_children?).returns true
    @user.expects(:update_attributes).returns(@user)
    @controller.expects(:by_user).returns('parent')
    @user.expects(:gender).at_least_once.returns('father')
    @user.expects(:existing_and_new_children).returns [Student.new]
    @user.stubs(:children).returns [mock(:first_name => 'child')]
    post :update, :method => :put
    assert_template('edit')
  end
end

