require 'test_helper'

class Upload::EnrollmentControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    Section.stubs(:find).returns(@section = Section.new)
    @section.stubs(:teacher).returns(@user)
    @user.stubs(:teaches?).returns true
    @user.stubs(:display_name).returns 'mr teacher'
    @section.stubs(:belongs_to?).returns true
  end

  def test_fail_login
    Upload::EnrollmentController.public_instance_methods(false).select{|m| !(m.to_s =~ /^_/)}.each do |method|
      @controller.stubs(:authorized?).returns(false)
      get method.to_sym, {}, {:school => :exists, :user => :exists}
      assert_redirected_to login_path
    end
  end

  def test_upload
    Upload.expects(:create).returns(mock(:valid? => true, :extension => '.xlsx', :data => [[]], :errors => {}))
    post :create, :filedata => 'file.xlsx', :section_id => 'section'
    assert_template 'describe_file'
  end

  def test_upload_fails
    Upload.expects(:create).returns(@upload = Upload.new)
    post :create, :filedata => 'file', :section_id => 'section'
    assert_template('new')
  end

  def test_new
    get :new, :section_id => 'section'
    assert_response :success
  end

  def test_bulk_upload
    EnrollmentUpload.expects(:open).returns(mock(:create_enrollment => stub(:num_inserts => 1)))
    post :create, :section => [1,2,''], :extension => '.xls', :section_id => 'section'
    assert_redirected_to sections_path
  end

  def test_bulk_upload_fail
    EnrollmentUpload.expects(:open).returns(@upload = EnrollmentUpload.new)
    @upload.expects(:create_enrollment).returns(nil)
    @upload.stubs(:data).returns([[]])
    @upload.stubs(:extension).returns('.xls')
    post :create, :extension => '.xls', :section_id => 'section'
    assert_template('describe_file')
  end

end

