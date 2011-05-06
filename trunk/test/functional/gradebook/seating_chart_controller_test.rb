require 'test_helper'

class Gradebook::SeatingChartControllerTest < ActionController::TestCase
  
  def setup
    generic_setup Teacher
    Section.expects(:find).returns(@section = Section.new)
    @section.expects(:teacher).at_least_once.returns(@user)
  end

  def test_new
    get :new, :section_id => 'id'
    assert_response :success
  end
  
  def test_show
    stub_seats
    get :show, :section_id => 'id'
    assert_response :success
  end

  def test_cannot_show_new
    @section.stubs(:rollbook_entries).returns([RollbookEntry.new])
    get :show, :section_id => 'id'
    assert_redirected_to new_section_seating_chart_path(@section)
  end
  
  def test_edit
    stub_seats
    get :edit, :section_id => 'id'
    assert_response :success
  end

  def test_create
    @section.stubs(:enrollment).returns(1)
    post :create, :section_id => 'id', :seat => {0 => {0 => '1'}}
    assert_redirected_to section_path(@section)
  end
  protected
  def stub_seats
    @section.stubs(:rollbook_entries).returns([RollbookEntry.new(:x => 1, :y => 1), RollbookEntry.new(:x => 1, :y => 2)])
    RollbookEntry.any_instance.stubs(:student).returns(stub(:full_name => 'student'))
  end
end
