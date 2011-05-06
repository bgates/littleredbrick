require 'test_helper'

class Gradebook::AttendanceControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    Section.expects(:find).returns(@section = Section.new)
    @section.expects(:teacher).at_least_once.returns(@user)
    @section.stubs(:to_param).returns 'id'
    School.stubs(:find).returns @school = School.new
  end

  def test_show
    get :show, :section_id => @section
    assert_template('show')
  end

  def test_edit
    get :edit, :section_id => @section
    assert_response :success
  end

  def test_update
    @section.expects(:update_attributes)
    put :update, :section_id => @section, :date => Date.today.to_s, :section => { :absence => {1 => '0', 3 => '5' }}
    assert_redirected_to edit_section_attendance_path(@section, :date => Date.today)
  end

  protected
  def stub_seats
    @section.stubs(:rollbook_entries).returns([RollbookEntry.new(:x => 1, :y => 1), RollbookEntry.new(:x => 1, :y => 2)])
    RollbookEntry.any_instance.stubs(:student).returns(stub(:full_name => 'student'))
  end
end

