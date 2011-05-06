require 'test_helper'

class SchoolSetupTest < ActionController::IntegrationTest

  def setup
    Staffer.any_instance.stubs(:make_admin).returns true
    host! "www.littleredbrick.com"
  end

  def test_create_school
    User.delete_all
    get '/signup'
    assert_template('new')
    assert_select "form[action='/signup']"
    assert_difference 'School.count' do
      create_school
    end
    assert_equal User.count, 1
    assert_redirected_to 'http://test.littleredbrick.com/login'
    follow_redirect!
    assert_template('new')
    assert flash[:notice]
    assert_select "form[action='login']"
    login
    assert_template('setup')
  end
  
  def test_setup_term
    prep_school_to_step :create_school
    assert_template('setup')
    assert_select "a[href=#{new_term_path}]", 'Set up a new term'
    assert_select "a[href=#{new_catalog_path}]", 'Create catalog'
    assert_select "a[href='/teachers/enter/multiple']", 0
    assert_select "a[href='/students/enter/multiple/']", 0
    
    get 'admin/terms/new'
    assert_template('new')
    create_term
    @term_path = term_path(assigns(:term))
    assert_redirected_to @term_path
    follow_redirect!
    
    assert_select '#primary', 0
    assert session[:initial]
    @track_path = term_track_path(assigns(:term), assigns(:tracks).first)
    assert_select 'h2', 'Marking Period Schedule'
    find_and_follow_link_to "#{@track_path}/edit"
    assert_template('edit')
    update_track
    assert_redirected_to @term_path
    follow_redirect!
    assert_select "a[href=/]"#, 'Return'
    get '/'
    assert_template('setup')
    assert_select 'a', :text => 'Set up a new term', :count => 0
  end

  def test_add_track
    assert_difference 'Track.count', 3 do
      prep_school_to_step :create_term
    end
    assert_select '#notice'
    @track_path = "/admin/terms/#{assigns(:term).id}/tracks"
    find_and_follow_link_to "#{@track_path}/new"
    assert_difference 'Track.count' do
      post @track_path, :commit => "Create Track", :term_id => assigns(:term).id, :track => {:new_marking_periods => [{:finish =>"2009-07-14", :start => "2009-07-13"}, {:finish => "2009-07-16", :start => "2009-07-15"}, {:finish => "2009-07-18", :start => "2009-07-17"}, {:finish => "2009-07-20", :start => "2009-07-19"}]}
    end
    assert_redirected_to "/admin/terms/#{assigns(:term).id}"
    follow_redirect!
  end
  
  def test_setup_catalog
    prep_school_to_step :create_term
    get '/'
    assert_template('setup')
    assert_select "a[href=#{new_catalog_path}]"
    get '/admin/catalog/new'
    assert_template('new')

    assert_difference 'Subject.count', 5 do
      create_catalog
    end
    assert flash[:notice]
    
    assert_select "a[href=#{edit_catalog_path}]", 'here'
  end

  def test_setup_teacher_accounts
    Role.stubs(:find_by_title).returns Role.new
    prep_school_to_step :create_catalog
    find_and_follow_link_to '/teachers/enter/multiple'
    assert_response :success
    assert_template('multiple')
    find_and_follow_link_to '/teachers/enter/names'
    assert_select 'form[action=/teachers/enter/names]'
    post '/teachers/enter/names', :names =>
      "Test Teacher
      Second Teacher"
    assert_template('details')
    assert_equal 2, assigns(:new_people).length
    assert_equal 'Second Teacher', assigns(:new_people).last.full_name

    assert_difference 'Teacher.count', 2 do
      post '/teachers/enter/details', :details => {1 => {:first_name => 'Test', :last_name => 'Teacher'}, 2 => {:first_name => 'Second', :last_name => 'Teacher'}}, :last => 'Save'
    end
    assert_redirected_to '/'
    follow_redirect!
    assert session[:initial]
    assert_template('setup')
  end

  def test_upload_student_accounts
    prep_school_to_step :create_term
    get '/'
    find_and_follow_link_to '/students/enter/multiple'
    assert_template('multiple')
    find_and_follow_link_to '/students/upload/new'
    post '/students/upload', :upload => { :filedata => fixture_file_upload('../uploads/upload/530 names.xls') }
    assert_template 'describe_file'
    post '/students/upload', :commit => "Set Up Accounts", :extension => ".xls", :import => {"6"=>"", "11"=>"", "7"=>"", "12"=>"", "8"=>"", "13"=>"", "9"=>"", "14"=>"", "0"=>"", "1"=>"first_name", "2"=>"", "3"=>"last_name", "4"=>"", "10"=>"grade", "5"=>""}
  end
  
  protected
  def create_school
    post '/signup', :school => {:domain_name => 'test', :name => 'Test School', :low_grade => 9, :high_grade => 12, :teacher_limit => 10}, :user => {:title => 'Mr', :first_name => 'Test', :last_name => 'Administrator', :authorization => {:login => 'test', :password => 'secret', :password_confirmation => 'secret'}, :email => 'user@test.edu'}, :teacher => 'no', :group => true
  end

  def login
    post '/login', :login => 'test', :password => 'secret'
    assert_redirected_to '/'
    follow_redirect!
  end

  def create_term
    post 'admin/terms', :term => {:low_period => 1, :high_period => 6, :start => '2009-09-01', :finish => '2010-06-15', :n_marking_periods => 4, :n_tracks => 3}
  end
  
  def update_track
    mp1, mp2, mp3, mp4 = assigns(:marking_periods).map(&:id)
    put @track_path, :track => {:existing_marking_periods => {mp1 => {:start => '2009-09-01', :finish => '2009-11-13'}, mp2 => {:start => '2009-11-16', :finish => '2010-01-15'}, mp3 => {:start => '2010-01-18', :finish => '2010-04-02'}, mp4 => {:start => '2010-04-05', :finish => '2010-06-15'}}}
  end

  def create_catalog
    post '/admin/catalog', :school => { :departments_attributes => {1 => {:name => 'Mathematics', :subjects_attributes => [{:name => 'Algebra'}, {:name => 'Geometry'}, {:name => 'Calculus'}, {:name => ''}]}, 2 => {:name => 'English', :subjects_attributes => [{:name => 'Poetry'}, {:name => 'Prose'}, {:name => ''}]}}}
    assert_redirected_to '/'
    follow_redirect!
  end

  def find_and_follow_link_to(link)
    assert_select "a[href=#{link}]"
    get link
  end
  
  def prep_school_to_step(step)
    create_school
    follow_redirect!
    login
    return if step == :create_school
    create_term
    follow_redirect!
    return if step == :create_term
    create_catalog
  end
=begin
    sanity checks on live data after importing students:

school = School.last
students = school.students.find(:all, :include => [:authorization, {:parents => :authorization}])

assert_equal students.select{|s| s.parents.length != 2}, []

assert_equal students.select{|s| s.login != (s.first_name + s.last_name).downcase}.length, 1
#assuming I use the 530 name file, which has 2 duplicate names

assert_equal students.select{|s| s.parents.any?{|p| !p.login.include?s.login}}, 0

assert_equal school.parents.find(:all, :include => :children).select{|p| p.children.length != 1}, []
=end
  
end
