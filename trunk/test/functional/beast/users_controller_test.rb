require 'test_helper'

class Beast::UsersControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = Fixtures.identify(:default)
    login_as :aaron
  end

  def test_should_get_index
    get :index, :scope => sections(:beast)
    assert_response :success
    assert assigns(:users)
    assert_select 'html>head'
  end

  def test_should_show_user
    get :show, :scope => sections(:beast), :id => users(:sam).id
    assert_response :success
    assert_select 'html>head'
  end

  def test_basic_reader_routing
    assert_routing("/discussions/1/members", { :controller => "beast/users", :action => "index", :scope => '1' })
    %w(school teachers help admin staff).each do |scope|
      assert_routing("/discussions/#{scope}/members", { :controller => "beast/users", :action => "index", :scope => scope })
    end
  end

end
