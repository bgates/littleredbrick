require 'test_helper'

class AccountUploadTest < ActiveSupport::TestCase

  def setup
    @upload = AccountUpload.create(:user => 'test', :type => 'test', :filedata => fixture_file_upload('../uploads/upload/5 duplicate names.xls'))
  end

  def test_should_detect_five_each_new_and_duplicate_names
    import
    assert_equal @good.length, @bad.length
    assert_equal 5, @bad.length
  end

  def test_should_detect_six_duplicates_if_one_login_already_exists
    Authorization.expects(:find_all_by_school_id).returns([Authorization.new(:login => 'arthurchalmers')])
    import
    assert_equal 6, @bad.length
    assert_equal 4, @good.length
  end

  def test_should_create_accounts_if_replacements_exist_for_all_duplicates
    import
    replacements = @good.map do |name|
      {:first_name => name.first_name, :last_name => name.last_name, :authorization => {:login => name.first_name.reverse}}
    end
    Delayed::Job.expects(:enqueue)
    import(replacements)
  end

  def test_replace_one
    import
    replaced = @good.first
    replacement = [
      {:first_name => replaced.first_name, :last_name => replaced.last_name, :authorization => {:login => 'replaced'}}
    ]
    import(replacement)
    assert_equal 5, @good.length
    assert_equal 4, @bad.length
    assert_equal 1, @ugly.length
  end

  def test_replace_two
    import
    first, second = @good.first, @good[1]
    replacements = [
      {:first_name => first.first_name, :last_name => first.last_name, :authorization => {:login => 'first'}, :grade => '', :id_number => ''},
      {:first_name => second.first_name, :last_name => second.last_name, :authorization => {:login => 'second'}, :grade => '', :id_number => ''}
    ]
    import(replacements)
    assert_equal 5, @good.length
    assert_equal 3, @bad.length
    assert_equal 2, @ugly.length
  end

  def test_teacher_limit
    import
    school = School.new(:teacher_limit => @good.length)
    assert @upload.teacher_limit_reached?(school, 'teachers')
  end

  def test_under_teacher_limit
    import
    school = School.new(:teacher_limit => @good.length + 1)
    assert ! @upload.teacher_limit_reached?(school, 'teachers')
  end

  protected

  def import(override = {})
    @good, @bad, @ugly = @upload.import_users({:import => {"6"=>"", "7"=>"", "8"=>"", "9"=>"", "0"=>"", "1"=>"first_name", "2"=>"", "3"=>"last_name", "4"=>"", "5"=>""}}, 'students', School.new, override)
  end
end

