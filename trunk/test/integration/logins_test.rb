require 'test_helper'

class LoginsTest < ActionController::IntegrationTest

  def setup
    Staffer.any_instance.stubs(:make_admin).returns true
    host! "www.littleredbrick.com"
    post '/signup', :school => {:domain_name => 'test', :name => 'Test School', :low_grade => 9, :high_grade => 12, :teacher_limit => 10}, :user => {:title => 'Mr', :first_name => 'Test', :last_name => 'Administrator', :authorization => {:login => 'test', :password => 'secret', :password_confirmation => 'secret'}, :email => 'user@test.edu'}, :teacher => 'no', :group => true
    follow_redirect!
  end

  def test_success
    get '/login'
    assert_template('new')

    post '/login', :login => 'test', :password => 'secret'
    assert_redirected_to '/'
    follow_redirect!
    assert_select 'div#notice'
  end

  def test_reset_password
    get '/alternate_login'
    assert_template('forgot_password')
    UserNotifier.expects(:password_bypass).returns(mock(:deliver))
    post '/account/reset_password', :email => 'user@test.edu'
    assert_redirected_to '/login'
    follow_redirect!
    assert_select 'div#notice'
  end

  def test_fail_reset
    post '/account/reset_password', :email => 'fail'
    assert_template('forgot_password')
    assert_select 'div#error'
  end

  def test_after_reset
    @user = School.find_by_domain_name('test').users.first
    @code = @user.authorization.bypass_code
    get "/bypass/#{@code}"
    assert_equal assigns(:school).authorizations.find_by_crypted_password(@code.reverse), @user.authorization
    assert_redirected_to '/account/edit'
  end
end

