require 'test_helper'

class Upload::GradesControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @teacher = @user
    sections = [Section.new]
    @teacher.stubs(:sections).returns(sections)
    sections.stubs(:find_by_id).returns(@section = Section.new)
  end

  def test_upload_possible
    @section.expects(:assignments).returns(stub(:size => 1))
    get :new, :section_id => 1
    assert_template('new')
  end

  def test_upload_impossible
    @section.expects(:assignments).returns(stub(:size => 0))
    get :new, :section_id => 1
    assert_template('new')
    assert_select '#content form', 0
    assert_select 'p', :text => /You cannot/
  end

  def test_upload_non_excel_fails
    Upload.expects(:create).returns(@upload = Upload.new)
    post :create, :section_id => 1, :Filedata => fixture_file_upload('../uploads/upload/not_a_csv_file.doc', 'application/msword')
    assert_template('new')
    assert_select 'div#errorExplanation'
  end

  def test_upload_good_file
    Upload.expects(:create).returns(@upload = Upload.new)
    @upload.expects(:valid?).returns(true)
    @upload.expects(:extension).returns('.xls')
    @upload.expects(:data).returns [[1]]
    stub_assignments
    post :create, :section_id => 1, :Filedata => fixture_file_upload('../uploads/upload/good.xls', 'application/vnd.ms-excel')
    assert_template 'describe_file'
    assert flash[:notice]
  end

  def test_update_fails
    @upload = Upload.new
    @upload.expects(:valid?).returns(false)
    @upload.expects(:extension).returns('.xlsx')
    GradeUpload.expects(:open).returns(@upload)
    @upload.expects(:prepare_grades).returns('fail msg')
    @upload.stubs(:data).returns([[]])
    stub_assignments
    post :create, :section_id => 1, :extension => :present
    assert_template('describe_file')
  end

  def test_upload_not_all_valid
    prep_upload(false)
    assert flash[:error]
  end

  def test_upload_all_valid
    prep_upload(true)
    assert flash[:notice]
  end

  def test_import_with_notice_of_missing_students
    @upload = mock(:valid? => true)
    GradeUpload.expects(:open).returns(@upload)
    @upload.expects(:prepare_grades).returns([])
    @upload.expects(:update_all).returns([stub(:valid? => true, :id => 'id')])
    @section.stubs(:rollbook_entries).returns([stub(:id => 1, :student => mock(:full_name => 'test name')), stub(:id => 2)])
    @section.stubs(:rollbook_entry_ids).returns [1, 2]
    @upload.expects(:collect_students).returns([2])
    post :create, :section_id => 1, :extension => :present
    assert_redirected_to section_gradebook_path(@section)
  end

  protected
  def prep_upload(response)
    @upload = mock(:valid? => true)
    GradeUpload.expects(:open).returns(@upload)
    @upload.expects(:prepare_grades).returns([])
    @upload.expects(:update_all).returns([stub(:valid? => response, :id => 'id')])
    @upload.expects(:collect_students).returns([]) if response
    post :create, :section_id => @section, :extension => :present
    assert_redirected_to section_gradebook_path @section
  end

  def stub_assignments
    @section.stub_path('assignments.limit.order').returns([Assignment.new(:date_due => Date.today)])
  end
end

