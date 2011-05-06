require 'test_helper'

class Term::TermsControllerTest < ActionController::TestCase

  def setup
    generic_setup Staffer
    @term = Term.new
    @term.stubs(:start_date).returns Date.today
    @term.stubs(:end_date).returns Date.today + 1
  end

  def test_fail_login
    @user.stubs(:admin?).returns(false)
    @request.session[:school] = @request.session[:user] = :exists
    get :edit, :id => 'term'
    assert_redirected_to login_path
  end

  def test_term_creation
    Term.any_instance.expects(:start).returns(Date.today)
    Term.any_instance.expects(:finish).returns(Date.today + 180)
    @terms = stub(:create => @term, :last => Term.new)
    @term.stubs(:valid?).returns true
    @school.expects(:terms).at_least_once.returns @terms
    post :create, :term => {}
    assert_redirected_to term_path(@term)
  end

  def test_term
    @term.stubs(:tracks).returns [Track.new]
    @school.expects(:terms).at_least_once.returns(stub(:count => 1, :last => @term))
    get :new
    assert_select 'select', 4
    assert_select 'fieldset', 4
  end

  def test_term_first
    get :new, {}, {:initial => true, :school => :exists, :user => :exists}
    assert_equal nil, assigns(:last_term)
    assert_select 'fieldset', 3
  end

  def test_allow_only_two_terms
    @school.expects(:terms).at_least_once.returns(stub(:count => 2, :last => @term))
    get :new
    assert_redirected_to term_url(@term)
  end

  def test_fail_creation
    @school.expects(:terms).at_least_once.returns(stub(:create => @bad_term = Term.new(:low_period => 2, :high_period => 1), :last => @term))
    post :create, :term => {}
    assert_template('new')
    assert_select ".ie_high"
    assert_select '.fieldWithErrors'
    assert_select 'fieldset', 4
  end

  def test_fail_archive
    @school.expects(:terms).at_least_once.returns(stub(:create => @last = Term.new, :last => @term))
    @last.expects(:valid?).returns(true)
    Track.expects(:update).returns([@track = Track.new])
    @track.expects(:valid?).returns(false)
    post :create, :term => {}, :track => {nil => {:archive => 'invalid_date'}}
    assert_template('new')
  end

  def test_succeed_archive
    @school.expects(:terms).at_least_once.returns(stub(:create => @term, :last => Term.new))
    @term.expects(:valid?).returns(true)
    Track.expects(:update).returns([@track = Track.new])
    @track.expects(:valid?).returns(true)
    post :create, :term => {}, :track => {nil => {:archive => 'valid'}}
    assert_redirected_to term_url(@term)
  end

  def test_edit
    @school.expects(:terms).at_least_once.returns(stub(:find => @term, :last => @term))
    get :edit, :id => 'present'
    assert_select 'select', 2
  end

  def test_succeed_update
    @school.expects(:terms).returns(stub(:find => @term))
    @term.expects(:update_attributes).returns(true)
    put :update, :id => 'present', :term => {}
    assert_redirected_to term_url(@term)
  end

  def test_fail_update
    @school.stubs(:terms).returns(stub(:find => @term, :last => @term))
    @term.expects(:update_attributes).returns(false)
    put :update, :id => 'present', :term => {}
    assert_template('edit')
  end

  def test_show
    @school.stubs(:terms).returns(mock(:find => @term, :detect => nil, :first => @term))
    @term.stubs(:tracks).returns([@track = Track.new])
    @term.stubs(:marking_periods).returns [stub(:to_param => 'mp_id')]
    get :show, :id => 'term'
    assert_response :success
  end
end

