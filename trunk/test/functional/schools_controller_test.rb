require 'test_helper'

class SchoolsControllerTest <  ActionController::TestCase 

  def setup
    stub_role
  end

  def test_show
    generic_setup Staffer
    School.expects(:find).returns @school 
    @term = Term.new(low_period: 1, high_period: 6)
    @school.stub_path('terms.includes.first').returns @term
    @term.stubs(:start_date).returns Date.today
    @term.stubs(:end_date).returns Date.today
    @school.name = "Test School"
    @school.expects(:students).returns([Student.new(:grade => 1), Student.new(:grade => 2), Student.new(:grade => 3), Student.new(:grade => 3)])
    get :show 
    assert_response :success
  end

  def test_new
    get :new
    assert_response :success
  end

  def test_create
    set_creation_expectations
    assert_difference 'School.count' do
      post :create, :school => {:name => 'test', :domain_name => 'test', :low_grade => 1, :high_grade => 10, :teacher_limit => '1'}, :user => {:first_name => 'tester', :last_name => 'testerino', :title => 'Sir', :authorization => {:login => 'testola', :password => 'admin', :password_confirmation => 'admin'}, :email => 'required@school.edu'}, :teacher => 'yes'
    end
    user = assigns(:user)                         
    assert user.valid?
    assert user.is_a?(Teacher)
    assert assigns(:user).admin?
    assert assigns(:school).valid?
    assert_redirected_to 'http://test.littleredbrick.com/login'
  end

  def test_create_routing
    assert_routing( { :method => 'post', :path => '/signup' },
                    { :controller => 'schools', :action => 'create' })
  end

  def test_create_staffer
    set_creation_expectations
    post :create, :school => {:name => 'test', :domain_name => 'test', :low_grade => 1, :high_grade => 10, :teacher_limit => '10'}, :user => {:first_name => 'tester', :last_name => 'testerino', :title => 'Sir', :authorization => {:login => 'testola', :password => 'admin', :password_confirmation => 'admin'}, :email => 'required@school.edu'}, :teacher => 'no', :group => true
    user = assigns(:user)
    assert user.valid?
    assert user.is_a?(Staffer)
    assert !user.is_a?(Teacher)
    assert assigns(:user).admin?
    assert assigns(:school).valid?
    assert_redirected_to 'http://test.littleredbrick.com/login'
  end

  def test_fail_create_school
    post :create, :school => {:name => 'test', :domain_name => schools(:default).domain_name, :low_grade => 1, :high_grade => 10, :teacher_limit => '1'}, :user => {:first_name => 'tester', :last_name => 'testerino', :title => 'Sir', :authorization => {:login => 'testola', :password => 'admin', :password_confirmation => 'admin'}}
    assert !assigns(:school).valid?
    assert !User.find_by_last_name('testola')
    assert_template('new')
  end

  def test_fail_create_user
    post :create, :school => {:name => 'test', :domain_name => 'bad name', :low_grade => 1, :high_grade => 10, :teacher_limit => '1'}, :user => {:first_name => 'tester', :last_name => 'testerino', :title => 'Sir', :authorization => {:login => 'testola', :password => 'adon', :password_confirmation => 'admin'}}, :teacher => 'yes'
    assert !assigns(:user).valid?
    assert !School.find_by_name('test')
    assert_template('new')
  end

  def test_edit
    set_session
    fake_admin
    get :edit
    assert_response :success
  end

  def test_update
    set_session
    fake_admin
    put :update, :school => {:name => 'test'}
    assert_redirected_to school_path
  end

  def test_update_fail
    set_session
    fake_admin
    put :update, :school => {:name => ''}
    assert_template('edit')
  end

  def test_search_form
    get :search
    assert_template('search')
  end

  def test_search_unique
    School.expects(:where).with(['(LOWER(name)) LIKE (?)', "test school%"]).returns([stub(:domain_name => 'test', :id => 100)])
    User.expects(:where).with(['first_name = ? AND last_name = ?', 'Test', 'User']).returns([User.new(:school_id => 100)])
    post :search, :school => ' Test School', :name => 'Test User'
    assert_redirected_to 'http://test.littleredbrick.com/login'
  end

  def test_search_multiple
    stub_school_search
    User.expects(:where).with(['first_name = ? AND last_name = ?', 'Test', 'User']).returns([stub(:school_id => 100), stub(:school_id => 200)])
    post :search, :school => ' Test School', :name => 'Test User'
    assert flash[:error]
    assert_template('search')
  end

  def test_search_multiple_narrow
    stub_school_search
    User.expects(:where).with(['first_name = ? AND last_name = ?', 'Test', 'User']).returns([stub(:school_id => 100)])
    post :search, :school => ' Test School', :name => 'Test User'
    assert_redirected_to 'http://test.littleredbrick.com/login'
  end

  def test_search_none
    School.expects(:where).with(['(LOWER(name)) LIKE (?)', "test school%"]).returns([])
    User.expects(:where).with(['first_name = ? AND last_name = ?', 'Test', 'User']).returns([])
    post :search, :school => ' Test School', :name => 'Test User'
    assert_equal assigns(:schools), []
    assert flash[:error]
    assert_template('search')
  end

  protected
  def fake_admin
    @user.expects(:admin?).at_least_once.returns(true)
  end

  def set_session
    @request.session[:school] = @request.session[:user] = :exists
    @controller.expects(:set_user).returns @user = Factory(:staffer, :school => schools(:default))
  end

  def stub_school_search
    School.expects(:where).with(['(LOWER(name)) LIKE (?)', "test school%"]).returns([stub(:name => 'Test School', :id => 100, :domain_name => 'test', :low_grade => 1, :high_grade => 6, :students => stub(:count => 100)), stub(:name => 'Test School', :id => 200, :domain_name => 'other', :low_grade => 9, :high_grade => 12, :students => stub(:count => 100))])
  end
  
  def set_creation_expectations
    School.any_instance.expects(:send_welcome_email)
  end
end
