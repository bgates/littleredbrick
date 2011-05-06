require 'test_helper'

class DummyController < ApplicationController
  def dummy
    render :text => 'pass'
  end

  def dummy_upload
    @return_value = handle_upload(params[:type])
    render :text => 'pass'
  end
  
  def rescue_action(e) raise e end
end

class ApplicationControllerTest < ActionController::TestCase
  
  def setup
    @controller = DummyController.new
  end

  def test_find_domain_given_session_school
    @request.session[:school] = 'school_id'
    School.expects(:find).with('school_id', :select => :id).returns(@school = School.new)
    get :dummy
    assert_equal assigns(:school), @school
  end
  
  def test_find_domain_given_session_user
    @request.session[:user] = 'testuser'
    @request.session[:school] = 'school_id'  
    @controller.expects(:set_user).returns @user = mock(:school => :school,
                                                        :id => :id)
    get :dummy
    assert_equal assigns(:current_user), @user
    assert_equal assigns(:school), :school
  end
  
  def test_find_domain_on_login
    prep_to_find_school(mock(:id => 'school_id'))
    School.expects(:find).with('school_id', :select => :id).returns(@school = School.new)
    get :dummy
    assert_equal assigns(:school), @school
    assert_equal 'school_id', @request.session[:school]
  end
  
  def test_find_school_fail
    get :dummy
    assert_redirected_to 'http://schoolfinder.littleredbrick.com/schools/search'
    assert_equal assigns(:school), nil
    assert_equal nil, @request.session[:school]
  end

  def test_style_setter
    @controller.expects(:domain_finder).returns(true)
    get :dummy, :stylesheet => 'user_selected_style'
    assert_equal 'user_selected_style', session[:style]
  end

  def test_set_back
    @controller.stubs(:domain_finder).returns(true)
    post :dummy
    assert_nil @request.session[:return_to]
    get :dummy
    assert_equal '/dummy_for_test', session[:return_to]
  end
  #TODO: what if session[:user] exists but not for the current school? should probably redirect from domain_finder
  protected
  def prep_to_find_school(school = nil)
    @request.expects(:subdomains).returns(%w(testschool))
    School.expects(:find_by_domain_name).with('testschool').returns(school)
  end
end
