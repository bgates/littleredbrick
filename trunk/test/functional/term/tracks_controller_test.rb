require 'test_helper'

class Term::TracksControllerTest < ActionController::TestCase

  def setup
    generic_setup(Staffer)
    term_setup
    @term.stubs(:tracks).returns(stub(:find => @track = Track.new))
    @track.stubs(:to_param).returns 'track'
  end

  def test_fail_login
    @user.stubs(:admin?).returns(false)
    @request.session[:school] = @request.session[:user] = :exists
    get :edit, :term_id => 'term', :id => 'track'
    assert_redirected_to login_path
  end
  
  def test_create
    @term.stubs(:tracks).returns(stub(:build => @track = Track.new, :size => 0))
    @track.expects(:save).returns(true)
    post :create, :term_id => @term, :track => {:new_marking_periods => [{:start => '2007-08-20', :finish => '2007-08-21'}, {:start => '2007-08-22', :finish => '2007-08-23'}]}
    assert_redirected_to term_path(@term)
  end
                                      
  def test_delete_track
    @track.expects(:occupied?).returns(false)
    delete :destroy, :id => @track, :term_id => @term
    assert_redirected_to term_path(@term)
  end

  def test_destroy_xhr
    @track.expects(:occupied?).returns(false)
    xhr :delete, :destroy, :id => @track, :term_id => @term
    assert_response :success
  end
  
  def test_fail_delete_occupied_track
    @track.expects(:occupied?).returns(true)
    delete :destroy, :id => @track, :term_id => @term
    assert flash[:error]
    assert_redirected_to term_path(@term)
  end

  def test_update
    @track.expects(:update_attributes).returns(true)
    put :update, :track => {:new_marking_periods => [{:start => Date.today, :finish => Date.today + 90}, {:start => Date.today + 100, :finish => Date.today + 180}]}, :term_id => 'term', :id => 'track'
    assert_redirected_to term_path(@term)
    assert flash[:notice]
  end

  def test_fail_update
    @term.stubs(:multitrack?).returns(false)
    @track.expects(:update_attributes).returns(false)
    @terms.stubs(:last).returns(Term.new)
    put :update, :track => {:new_marking_periods => [{:start => Date.today, :finish => Date.today + 90}, {:start => Date.today + 80, :finish => Date.today + 180}]}, :term_id => 'term', :id => 'track'
    assert_template('edit')
  end

  def test_fail_create
    @term.expects(:tracks).at_least_once.returns(stub(:build => @track = Track.new, :size => 0))
    @track.expects(:save).returns(false)
    @terms.stubs(:last).returns(Term.new)
    post :create, :term_id => @term, :track => {:new_marking_periods => [{:start => '2007-08-20', :finish => '2007-08-21'}, {:start => '2007-08-22', :finish => '2007-08-23'}]}
    assert_template('new')
  end

  def test_new
    @term.stubs(:tracks).returns(stub(:build => @track = Track.new, :size => 0))
    get :new, :term_id => 'term'
    assert_template('new')
  end

  def test_edit
    @term.stubs(:multitrack?).returns(false)
    get :edit, :term_id => 1, :id => 1
    assert_template('edit')
  end
end
