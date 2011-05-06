require 'test_helper'

class SessionControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = @request.session[:user] = :exists
    User.stubs(:where).with(["users.id = ? AND school_id = ?", :exists, :exists]).returns stub(:includes => stub(:first => @teacher = Teacher.new))
    @teacher.stubs(:school).returns(@school = School.new)
  end

  def test_fail_bad_subdomain
    @request.session[:school] = @request.session[:user] = nil
    @request.host = 'nonexistent.littleredbrick.com'
    get :new
    assert_response :redirect
  end

  def test_should_login
    Authorization.expects(:authenticate).returns(@teacher)
    @teacher.stubs(:id).returns 'id'
    post :create, :login => 'aaron', :password => 'testy'
    assert_response :redirect
    assert_equal 'id', session[:user]
  end

  def test_should_login_as_parent_and_id_single_child
    @controller.expects(:current_user).at_least_once.returns @parent = Parent.new
    @parent.expects(:logins).returns([1,2])
    @parent.expects(:children).at_least_once.returns([@student = Student.new])
    @student.stubs(:id).returns 'id'
    Authorization.expects(:authenticate).returns(@parent)
    post :create, :login => 'aaron', :password => 'testy'
    assert_equal session[:child], 'id'
    assert_redirected_to home_path
  end

  def test_should_login_as_parent_redirect_to_select_child
    @controller.expects(:current_user).at_least_once.returns @parent = Parent.new
    @parent.expects(:logins).returns([1,2])
    @parent.expects(:children).at_least_once.returns([Student.new, Student.new])
    Authorization.expects(:authenticate).returns(@parent)
    post :create, :login => 'aaron', :password => 'testy'
    assert_nil session[:child]
    assert_redirected_to session_path
  end

  def test_should_login_and_remember_url
    Authorization.expects(:authenticate).returns(@teacher)
    post :create, :login => 'aaron', :password => 'testy', :to => '%2Fdiscussions%2F1%2Fforums%2F2'
    assert_redirected_to forum_path(1,2)
  end

  def test_remember_me
    Authorization.expects(:authenticate).returns(@teacher)
    @teacher.stubs(:id).returns 'id'
    @school.stubs(:id).returns 'school'
    @teacher.stubs(:authorization).returns @auth = Authorization.new
    @auth.expects(:reset_login_key!).returns 'key'
    post :create, :login => 'aaron', :password => 'testy', :remember_me => "1"
    assert_equal("id;school;key", cookies['login_token'])
  end

  def test_should_fail_login
    post :create, :login => 'aaron', :password => 'bad'
    assert_response :success
    assert_template 'new'
    assert_nil session[:user_id]
  end

  def test_should_logout
    @teacher.stub_path('logins.find.update_attribute')
    get :destroy
    assert_redirected_to login_path
    assert_nil session[:user_id]
  end

  def test_should_find_no_user_from_empty_session
    get :new, {}, :school => :exists
    assert_equal 0, @controller.send(:current_user)
  end

  def test_should_find_current_user_from_session
    @request.session[:user] = :exists
    get :new
    assert_equal @teacher, @controller.send(:current_user)
  end

  def test_should_show_negative_logged_in_status
    @request.session[:user] = nil
    get :new
    assert !@controller.send(:logged_in?)
  end

  def test_bypass
    @school.stubs(:authorizations).returns(mock(:find_by_crypted_password => mock(:user => @user = User.new)))
    get :bypass, :id => 'test'
    assert_redirected_to edit_account_path
  end

  def test_fail_bypass
    @school.stubs(:authorizations).returns(mock(:find_by_crypted_password => nil))
    get :bypass, :id => 'fail'
    assert_redirected_to login_path
  end

  def test_admin
    @controller.stubs(:current_user).returns(@teacher = Teacher.new)
    @teacher.expects(:admin?).returns(true)
    put :update
    assert session[:admin]
    assert_redirected_to home_path
  end

  def test_admin_fail
    @controller.stubs(:current_user).returns(@teacher = Teacher.new)
    put :update
    assert_redirected_to home_path
  end

  def test_teacher
    @request.session[:teacher] = true
    @controller.stubs(:current_user).returns(Teacher.new)
    put :update
    assert_redirected_to home_path
    assert !session[:admin]
  end

  def test_child
    @controller.stubs(:current_user).returns(@parent = Parent.new)
    @parent.expects(:children).returns(mock(:find => mock(:id => 'new')))
    put :update, :id => 'old'
    assert_redirected_to home_path
    assert_equal session[:child], 'new'
  end

  def test_routing
    assert_routing 'login', :controller => 'session', :action => 'new'
  end
end
