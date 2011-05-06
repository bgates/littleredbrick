require 'test_helper'

class EventsControllerTest < ActionController::TestCase

  def setup
    generic_setup Teacher
    @user.stubs(:admin?).returns true
    @month, @year = Date.today.mon.to_s, Date.today.year.to_s
  end

  def test_calendar
    event = Event.new(:date => Date.today, :name => 'test event', 
                      :invitable_type => 'School')
    event.stubs(:id).returns 'id'
    span = Event.new(:date => Date.today, :name => 'nonevent')
    @user.stubs(:all_events).returns [event, span]
    get :index, :year => Date.today.year, :month => Date.today.month
    assert_select 'td.specialDay ul li a', 'test event'
    assert_select "td.specialDay ul li span.nonacademic", 'nonevent'
  end

  def test_calendar_url
    year, month = Date.today.year, Date.today.month
    @user.expects(:all_events).returns([])
    get :index, :year => year, :month => month
    assert_equal calendar_path, "/calendar/#{year}/#{month}"
    assert_generates("/calendar/#{year}/#{month + 1}", {:controller => 'events', :action => 'index', :year => year.to_s, :month => (month + 1).to_s})
    assert_routing("/calendar/#{year}/#{month}", :controller => 'events', :action => 'index', :year => year.to_s, :month => month.to_s)
    event = edit_event_url(1)
    assert_equal event, 'http://test.host/calendar/events/1/edit'
    assign = assignment_as_event_url(2)
    assert_equal assign, 'http://test.host/calendar/assignments/2'
    assert_routing('/calendar/assignments/3', {:controller => 'events', :action => 'assignment', :assignment_id => '3'})
    student = student_calendar_url(:year => year, :month => month, :student_id => 4)
    assert_equal student, "http://test.host/calendar/#{year}/#{month}/student/4"
  end

  test "generate month automatically" do
    assert_generates "calendar/#{@year}/#{@month}", :controller => 'events', :action => 'index', :year => @year 
  end

  test "recognize" do
    assert_recognizes({ :controller => 'events', :action => 'index', :year => @year, :month => @month }, "calendar/#{@year}/#{@month}")
  end

  def test_show
    Event.expects(:find).returns(@event = Event.new(:date => Date.today))
    @event.expects(:viewable_by?).returns(true)
    @event.stubs(:to_param).returns 'id'
    get :show, :id => 'test'
    assert_template('show')
  end

  def test_day
    year, month = Date.today.year, Date.today.month
    @user.expects(:all_events).returns([])
    get :index, :year => year, :month => month, :day => 20
    assert_template('day')
  end
  
  def test_edit
    Event.expects(:find).returns(@event = Event.new(:date => Date.today))
    @event.stubs(:to_param).returns('id')
    get :edit, :id => 'test'
    assert_template('edit')
  end

  def test_new
    get :new
    assert_response :success
  end

  def test_create
    Event.any_instance.expects(:save).returns(true)
    post :create, :audience => 'User', :event => {:name => 'test', :date => Date.today}
    assert flash[:notice]
    assert_redirected_to calendar_url
  end

  def test_update_section_event
    stub_update
    assert flash[:notice]
    assert_redirected_to calendar_url
  end

  def test_update_fail
    stub_update(false)
    assert_template('edit')
  end
  
  def test_create_fail
    post :create, :audience => 'User', :event => {:name => '', :date => Date.today}
    assert_template('new')
  end

  def test_require_ownership
    Event.expects(:find).returns(@event = Event.new(:date => Date.today, :creator_id => 100))
    get :edit, :id => 404
    assert_redirected_to login_path
  end
  
  def test_destroy
    prep_destroy
    delete :destroy, :id => 'test'
    assert flash[:notice]
    assert_redirected_to calendar_url
  end

  def test_destroy_xhr
    prep_destroy
    xhr :delete, :destroy, :id => 'test'
    assert_response :success
  end
  
  def test_assignment
    Assignment.expects(:find).returns(@assignment = Assignment.new(:date_assigned => Date.today, :date_due => Date.today + 1))
    @assignment.stubs(:to_param).returns 'id'
    @assignment.expects(:section).returns(@section = Section.new)
    @section.stubs(:teacher).returns stub(:to_param => 'teacher')
    MarkingPeriod.expects(:find_by_track_id_and_reported_grade_id).returns(mock(:position => 1))
    get :assignment, :assignment_id => @assignment
    assert_template('gradebook/assignments/show')
  end

  protected
  def stub_update(response = true)
    Event.expects(:find).returns(@event = Event.new(:date => Date.today))
    @event.expects(:update_attributes).with({'date' => Date.today, 'invitable_type' => 'Section', 'invitable_id' => '1'}).returns(response)
    @event.stubs(:to_param).returns('id')
    put :update, :audience => '1', :event => {:date => Date.today}, :id => 'test'
  end

  def prep_destroy
    Event.expects(:find).returns(@event = Event.new(:date => Date.today))
    @event.expects(:destroy).returns(true)
  end
end
