require 'test_helper'

class AccountManipulationTest < ActionController::IntegrationTest

  def setup
    Staffer.any_instance.stubs(:make_admin).returns true
    host! "www.littleredbrick.com"
    User.delete_all
    get '/signup'
    create_school
    follow_redirect!
    login
  end

  def test_change_own_account
    get '/account/edit'
    change_account
    assert_redirected_to '/'
    assert Authorization.find_by_login('different')
  end

  def test_change_other_account
    add_a_student
    logout_then_back_in_as('fullname', 'fullname')
    assert_redirected_to '/account/edit'
    change_account
    logout_then_back_in_as('different', 'fullname')
    assert_redirected_to '/'
  end

  def test_reset_other_account
    add_a_student
    assert Authorization.find_by_login('fullname')
    logout_then_back_in_as('fullname', 'fullname')
    change_account
    assert Authorization.find_by_login('different')
    logout_then_back_in_as('test', 'secret')
    assert_redirected_to '/'
    @student = Student.find_by_first_name('Full')
    student_path = "/students/#{@student.id}"
    put student_path, :student => {:reauthorize => '1'}
    assert_redirected_to "#{student_path}"
    assert_equal Authorization.find_by_user_id(@student).login, 'fullname'
  end
  protected

  def add_a_student
    get '/students/new'
    post '/students', :student => {:first_name => 'Full', :last_name => 'Name', :authorization => {:password => ''}}
  end

  def change_account
    put '/account', :user => {:authorization => {:login => 'different'}}
  end

  def create_school
    post '/signup', :school => {:domain_name => 'test', :name => 'Test School', :low_grade => 9, :high_grade => 12, :teacher_limit => 10}, :user => {:title => 'Mr', :first_name => 'Test', :last_name => 'Administrator', :authorization => {:login => 'test', :password => 'secret', :password_confirmation => 'secret'}, :email => 'user@test.edu'}, :teacher => 'no', :group => true
  end

  def login
    post '/login', :login => 'test', :password => 'secret'
    follow_redirect!
  end

  def logout_then_back_in_as(login, password)
    delete '/logout'
    post '/login', :login => login, :password => password
  end
end

