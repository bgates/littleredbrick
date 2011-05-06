require 'test_helper'

class UploadTest < ActiveSupport::TestCase

  def test_open
    stub_open('good.xls')
    assert_equal @upload.data, [[1,100],[2,98]]
    assert @upload.is_a?('.xls')
    assert_equal '.xls', @upload.extension
  end

  def test_open_doc
    stub_open('not_a_csv_file.doc')
    assert_equal [], @upload.data
    assert @upload.empty?
    assert !@upload.is_a?('spreadsheet')
  end

  def test_save
    FileUtils.expects(:mkdir_p)
    File.expects(:open).with("#{Rails.root}/tmp/uploads/name", 'wb')
    Upload.new.save('name')
  end

  def test_class_save
    File.expects(:open).with("#{Rails.root}/tmp/uploads/name", 'wb').yields(@f = mock())
    @f.expects(:puts).with(:data).returns(:file)
    @data = mock(:read => :data)
    assert_equal Upload.save('name', @data), :file
  end

  def test_invalid_if_no_file
    @upload = Upload.new
    assert !@upload.valid?
    assert !@upload.errors[:filedata].empty?
  end

  def test_must_be_spreadsheet
    @upload = Upload.new(@file = mock(:path => 'path'))
    assert !@upload.valid?
    assert !@upload.errors[:filedata].empty?
  end

  def test_invalid_if_empty
    @file = stub(:path => 'path.xls')
    Upload.any_instance.stubs(:is_a?).with('spreadsheet').returns(true)
    Excel.stubs(:new).with('path.xls').returns(stub(:first_row => 0, :last_row => 0, :row => [], :default_sheet => 'sheet 1'))
    @upload = Upload.new(@file)
    assert_equal 'path.xls', @upload.name
    assert_equal [[]], @upload.data
    assert !@upload.valid?
    assert !@upload.errors[:filedata].empty?
  end

  protected

  def stub_open(file)
    File.stubs(:join).returns(File.dirname(__FILE__) + '/../uploads/upload/' + file)
    @upload = Upload.open(file)
  end
end

