require 'test_helper'

class Term::MarkingPeriodsControllerTest < ActionController::TestCase

  def setup
    generic_setup Staffer
    term_setup
    @controller.stubs(:authorized?).returns(true)
  end

  def test_add_marking_period
    @term.expects(:tracks).returns([@track = Track.new])
    @track.expects(:finish).returns(Date.today)
    @track.expects(:marking_periods).times(2).returns(@mp = Track.new.marking_periods)
    @mp.expects(:last).returns(mock(:update_attributes => true))
    dates = {}
    dates['0'] = {:start => (Date.today + 1).to_s(:db), 
                  :finish => (Date.today + 30).to_s(:db)}
    @term.expects(:reported_grades).returns(mock(:create => true))
    post :create, :term_id => @term, :marking_period => dates
    assert_redirected_to term_path(assigns(:term))
  end

  def test_fail_add
    @term.expects(:tracks).returns([@track = Track.new])
    @track.stubs(:finish).returns(Date.today)
    dates = {}
    dates['0'] = {:start => 'invalid_date',
                  :finish => (Date.today + 30).to_s(:db)}
    post :create, :term_id => @term, :marking_period => dates
    assert_template('new')
    assert_select '.fieldWithErrors'
  end

  def test_delete_marking_period_xhr
    @school.stub_path('reported_grades.find').returns(@g = ReportedGrade.new)
    @g.expects(:destroy).returns(true)
    xhr :delete, :destroy, :id => 1, :term_id => 1
  end

  def test_new
    get :new, :term_id => @term
    assert_template('new')
  end
end

