require 'test_helper'

class Upload::UsersControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns true
    School.stubs(:find).returns @school
    @school.teacher_limit = 10
    @school.stubs(:id).returns 100
  end

  def test_upload_empty
    Upload.expects(:create).returns(Upload.new)
    post :create, :Filedata => 'test', :id => 'students'
    assert_template 'new'
    assert_select "#errorExplanation"
  end

  def test_upload
    Upload.expects(:create).returns(mock(:valid? => true, :extension => '.xls', :data => [[]], :errors => {}))
    post :create, :Filedata => 'test', :id => 'students'
    assert_template 'describe_file'
    assert flash[:notice]
  end

  def test_upload_data_fails
    AccountUpload.expects(:open).returns mock(:data => [[1]], :errors => {}, :extension => '.xls')
    post :create, :import => {0 => 'no_name'}, :extension => :present, :id => 'students'
    assert_template 'describe_file'
    assert flash[:error]
  end

  def test_upload_data_initial
    @request.session[:initial] = true
    AccountUpload.expects(:open).returns(@upload = mock())
    @upload.expects(:import_users).returns([[:student],[], []])
    @controller.expects(:msg).returns(nil)
    post :create, :import => {0 => 'first_name', 1 => 'last_name'}, :extension => :present, :id => 'students'
    assert_redirected_to '/'
  end

  def test_upload_data
    AccountUpload.expects(:open).returns(@upload = mock())
    @upload.expects(:import_users).returns([[:student],[], []])
    @controller.expects(:msg).returns(nil)
    post :create, :import => {0 => 'first_name', 1 => 'last_name'}, :extension => :present, :id => 'students'
    assert_redirected_to students_path
  end

  def test_upload_hits_teacher_limit
    prep_teacher_upload
    assert_redirected_to teachers_path
  end

  def test_upload_hits_initial_teacher_limit
    prep_teacher_upload(true)
    assert_redirected_to home_path
  end

  protected

  def prep_teacher_upload(initial = false)
    AccountUpload.expects(:open).returns(@upload = mock())
    @teacher = Teacher.new(:first_name => 'Pass', :last_name => 'Word')
    @teacher.stubs(:login).returns('password')
    @upload.expects(:import_users).returns([[@teacher],[], []])
    post :create, {:import => {0 => 'first_name', 1 => 'last_name'}, :id => 'teachers', :extension => :present}, {:school => :exists, :user => :exists, :initial => initial}
  end

  def upload_file
    post :create, {:id => 'students', :upload => 'Upload', :Filedata => fixture_file_upload('../uploads/upload/5 duplicate names.xls', 'xls')}, {:school => :exists, :user => :exists}
    assert_template 'describe_file'
    post :create, {:id => 'students', :extension => '.xls', :import=>{"6"=>"", "7"=>"", "8"=>"", "9"=>"", "0"=>"", "1"=>"first_name", "2"=>"", "3"=>"last_name", "4"=>"", "5"=>""}}, {:school => :exists, :user => :exists}
  end
end

