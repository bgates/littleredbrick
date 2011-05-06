require 'test_helper'

class People::EnterControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns true
    School.stubs(:find).returns @school
    @school.teacher_limit = 10
    @school.stubs(:id).returns 100
  end

  def test_login_fail
    %w(multiple names).each do |method|
      @user.stubs(:admin?).returns false
      get method.to_sym, {:id => 'students'}, {:school => :exists, :user => :user}
      assert_redirected_to login_path
    end
  end

  def test_names_fail_nameless
    post :names, :names => "", :id => 'students'
    assert_select 'div#error', 'Please enter at least one name.'
    assert_template 'names'
  end

  def test_names_students
    post :names, :names => "Bob Jones\r\nTom Smith", :id => 'students'
    assert_template 'details'
    assert_tag :tag => 'tr', :children => {:count => 4, :only => {:tag => 'td'}}
  end

  def test_names_teachers
    post :names, :names => "Bob Jones\r\nTom Smith", :id => 'admin/administrators'
    assert_template 'details'
    assert_tag :tag => 'tr', :children => {:count => 4, :only => {:tag => 'td'}}
  end

  def test_details_empty
    post :details, :id => 'teachers', :details => {}
    assert_template('details')
  end

  def test_details_student_save_and_redisplay
    post :details, :details => {0 => {:first_name => 'Bob', :last_name => 'Jones', :grade => '9'}}, :more => 'save and enter more people', :id => 'students'
    assert_equal 9, Student.find_by_last_name('Jones').grade
    assert_equal assigns(:new_people).length, 8
    assert_template 'details'
  end

  def test_details_teacher_valid
    stub_role
    details = {0 => {:first_name => 'Sebastian', :last_name => 'Jones', :title => 'Mr'}, 1 => {:first_name => 'Oswald', :last_name => 'Paul'}}
    post :details, :id => 'teachers', :details => details, :last => 'save'
    assert_equal 'Mr', Teacher.find_by_last_name('Jones').title
    assert_equal 'Paul', Teacher.find_by_first_name('Oswald').last_name
    assert_equal assigns(:new_people), []
    assert_redirected_to home_path
  end

  def test_redisplay_invalid_people
    post :details, :details => {0 => {:first_name => 'Bob', :grade => '9'}, 1 => {:first_name => 'Oswald', :last_name => 'Paul'}}, :more => 'save and enter more people', :id => 'students'
    assert_equal assigns(:new_people).length, 1
    assert_equal 'Paul', Student.find_by_first_name('Oswald').last_name
    assert_template 'details'
    assert_select "input.fieldWithErrors"
  end

  def test_cant_enter_too_many_teachers
    @controller.expects(:set_saveable_and_new)
    @controller.instance_variable_set(:@saveable, [@user = User.new])
    @user.stubs(:login).returns ''
    @controller.expects(:teacher_limit_reached?).returns true
    post :details, :id => 'teachers', :details => {0 => {:first_name => 'Charles', :last_name => 'Barkley', :title => 'Sir'}, 1 => {:first_name => 'Charles', :last_name => 'Oakley', :title => 'Mr'}}, :last => 'true'
    assert_redirected_to home_path
  end
=begin this needs to be integration test since it spans controllers now
  def test_upload_accounts
    Delayed::Job.expects(:enqueue)
    upload_file
    assert_template('details')
    assert flash[:pending_import]
    assert_equal 5, assigns(:saveable).length
    assert_equal 5, assigns(:new_people).length
    assert_equal 0, assigns(:substitutes).length
    post_details({}, flash)
    assert_redirected_to home_path
    #assert_equal 10, assigns(:saveable).length
    #assert_equal 0, assigns(:new_people).length
  end

  def test_upload_with_duplicates_needs_substitute
    upload_file
    delta = {5 => {:grade=>"", :id_number=>"", :authorization => {:login=>"geraldinehinds"}, :first_name => "Geraldine", :last_name => "Hinds"}}
    post_details(delta, flash)
    assert_template('details')
    assert_equal 5, assigns(:saveable).length
    assert_equal 1, assigns(:new_people).length
    assert_equal 4, assigns(:substitutes).length
  end

  def test_upload_for_all_the_marbles
    Delayed::Job.expects(:enqueue)
    upload_file
    assert_template('details')
    assert flash[:pending_import]
    assert_equal 5, assigns(:saveable).length
    assert_equal 5, assigns(:new_people).length
    assert_equal 0, assigns(:substitutes).length
    post_details({}, flash)
    assert_redirected_to home_path
    assert_equal 10, assigns(:saveable).length
    assert_equal 0, assigns(:new_people).length
  end

  def test_upload_with_duplicates_needs_substitute
    upload_file
    delta = {5 => {:grade=>"", :id_number=>"", :authorization => {:login=>"geraldinehinds"}, :first_name => "Geraldine", :last_name => "Hinds"}}
    post_details(delta, flash)
    assert_template('details')
    assert_equal 5, assigns(:saveable).length
    assert_equal 1, assigns(:new_people).length
    assert_equal 4, assigns(:substitutes).length
  end
=begin
  def test_upload_for_all_the_marbles
    Delayed::Job.expects(:enqueue)
    upload_file
    delta = {5 => {:grade=>"", :id_number=>"", :authorization => {:login=>"geraldinehinds"}, :first_name => "Geraldine", :last_name => "Hinds"}}
    post_details(delta, flash)
    post :details, {:id => 'students', :details => {1 => {:grade => '', :id_number => '', :authorization => {:login => 'viable'}, :first_name => 'Geraldine', :last_name => 'Hinds'}}, :last => 'Save'}, {:school => :exists, :user => :exists}, flash
    assert_equal 0, assigns(:new_people).length
  end
=end
  protected
  def post_details(delta = {}, flash)
    if delta.empty?
      Student.any_instance.stubs(:save).returns true
    end
    details = {
    1 => {:grade => '', :id_number => '', :authorization => {:login => 'arthurchalmers1'}, :first_name => 'Arthur', :last_name => 'Chalmers'},
    2 => {:grade => "", :id_number =>"", :authorization => {:login => "jeremyjackson1"}, :first_name => "Jeremy", :last_name => "Jackson"},
    3 => {:grade => "", :id_number => "", :authorization => {:login => "carolynhuertas1"}, :first_name => "Carolyn", :last_name => "Huertas"},
    4 => {:grade => "", :id_number => "", :authorization => {:login => "nellmcquiston1"}, :first_name =>"Nell", :last_name => "Mcquiston"},
    5 => {:grade=>"", :id_number=>"", :authorization => {:login=>"geraldinehinds1"}, :first_name => "Geraldine", :last_name => "Hinds"}}.merge(delta)
    post :details, {:id => 'students', :details => details, :last => 'Save'}, {:school => :exists, :user => :exists}, flash
  end

  def prep_teacher_upload(initial = false)
    AccountUpload.expects(:open).returns(@upload = mock())
    @teacher = Teacher.new(:first_name => 'Pass', :last_name => 'Word')
    @teacher.stubs(:login).returns('password')
    @upload.expects(:import_users).returns([[@teacher],[], []])
    post :import_users, {:import => {0 => 'first_name', 1 => 'last_name'}, :id => 'teachers'}, {:school => :exists, :user => :exists, :initial => initial}
  end

  def upload_file
    post :upload, {:id => 'students', :upload => 'Upload', :Filedata => fixture_file_upload('../uploads/upload/5 duplicate names.xls', 'xls')}, {:school => :exists, :user => :exists}
    assert_redirected_to :action => 'describe_file', :id => 'students', :extension => '.xls'
    post :import_users, {:id => 'students', :extension => '.xls', :import=>{"6"=>"", "7"=>"", "8"=>"", "9"=>"", "0"=>"", "1"=>"first_name", "2"=>"", "3"=>"last_name", "4"=>"", "5"=>""}}, {:school => :exists, :user => :exists}
  end
end

