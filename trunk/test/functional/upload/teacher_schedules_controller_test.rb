require 'test_helper'

class Upload::TeacherSchedulesControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @teacher = @user
    @controller.stubs(:authorized?).returns(true)
    @school.stub_path('teachers.find').returns(@teacher)
    @teacher.stubs(:id).returns 'id'
    terms = [ @term = Term.new(:low_period => 1, :high_period => 5) ]
    @school.stubs(:terms).returns terms
  end

  def test_import
    TeachingUpload.stubs(:open).returns(stub(:create_sections => 1, :valid? => true))
    @school.stub_path('terms.first.tracks.length').returns 1
    post :create, :extension => :present
    assert_redirected_to teachers_path
  end
  
  def test_import_initial
    @request.session[:initial] = true
    TeachingUpload.stubs(:open).returns(stub(:create_sections => 1, :valid? => true))
    @school.stub_path('terms.first.tracks.length').returns 1
    post :create, :extension => :present
    assert_redirected_to home_path
  end
  
  def test_import_fail
    TeachingUpload.stubs(:open).returns(@upload = TeachingUpload.new)
    @upload.stubs(:valid?).returns(false)
    @upload.stubs(:create_sections).returns(0)
    @upload.stubs(:data).returns([[]])
    @upload.stubs(:extension).returns('.xls')
    post :create, :extension => :present
    assert_template('describe_file')
  end

end
