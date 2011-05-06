require 'test_helper'

class UploadAccountsTest < ActionController::IntegrationTest

  def setup
    Staffer.any_instance.stubs(:make_admin).returns true
    host! "www.littleredbrick.com"
    create_school
    login
  end

  def test_upload_accounts
    Delayed::Job.expects(:enqueue)
    assert_template('setup')
    get '/students/enter/multiple'
    assert_template('multiple')
    get '/students/upload/new'
    post '/students/upload', :upload => { :filedata => fixture_file_upload('../uploads/upload/5 duplicate names.xls') }
    assert_template 'describe_file'
    post '/students/upload', :extension => '.xls', "import"=>{"6"=>"", "7"=>"", "8"=>"", "9"=>"", "0"=>"", "1"=>"first_name", "2"=>"", "3"=>"last_name", "4"=>"", "5"=>""}
    assert_template('details')
    assert flash[:pending_import]
    assert_equal 5, assigns(:saveable).length
    assert_equal 5, assigns(:new_people).length
    assert_equal 0, assigns(:substitutes).length
    post '/students/enter/details', {:details => {
    1 => {:grade => '', :id_number => '', :authorization => {:login => 'arthurchalmers1'}, :first_name => 'Arthur', :last_name => 'Chalmers'},
    2 => {:grade => "", :id_number =>"", :authorization => {:login => "jeremyjackson1"}, :first_name => "Jeremy", :last_name => "Jackson"},
    3 => {:grade => "", :id_number => "", :authorization => {:login => "carolynhuertas1"}, :first_name => "Carolyn", :last_name => "Huertas"},
    4 => {:grade => "", :id_number => "", :authorization => {:login => "nellmcquiston1"}, :first_name =>"Nell", :last_name => "Mcquiston"},
    "5"=>{"grade"=>"", "id_number"=>"", "authorization"=>{"login"=>"geraldinehinds1"}, "first_name"=>"Geraldine", "last_name"=>"Hinds"}}, :last => 'Save'}
    assert_redirected_to '/'
    assert_equal 10, assigns(:saveable).length
    assert_equal 0, assigns(:new_people).length
  end

  def test_upload_duplicates
    Delayed::Job.expects(:enqueue)
    post '/students/upload', :upload => { :filedata => fixture_file_upload('../uploads/upload/3 of 1 name.ods') }
    post '/students/upload?extension=.ods', "header_row"=>"true", "import"=>{"1"=>"last_name", "0"=>"first_name", "2"=>""}
    assert_template('details')
    assert flash[:pending_import]
    assert_equal 1, assigns(:saveable).length
    assert_equal 2, assigns(:new_people).length
    post '/students/enter/details', {:details => {
      1 => {:grade => '', :id_number => '', :authorization => {:login => 'first_change'}, :first_name => 'Triple', :last_name => 'Play'},
      2 => {:grade => '', :id_number => '', :authorization => {:login => 'second_change'}, :first_name => 'Triple', :last_name => 'Play'}
    }, :last => 'Save'}
    assert_redirected_to '/'
    assert_equal 3, assigns(:saveable).length
    assert_equal 0, assigns(:new_people).length
    assert_equal 2, assigns(:substitutes).length
  end
  protected

  def create_school
    post_via_redirect '/signup', :school => {:domain_name => 'test', :name => 'Test School', :low_grade => 9, :high_grade => 12, :teacher_limit => 10}, :user => {:title => 'Mr', :first_name => 'Test', :last_name => 'Administrator', :authorization => {:login => 'test', :password => 'secret', :password_confirmation => 'secret'}, :email => 'user@test.edu'}, :teacher => 'no', :group => true
  end

  def login
    post_via_redirect 'http://test.littleredbrick.com/login', :login => 'test', :password => 'secret'
  end

end

