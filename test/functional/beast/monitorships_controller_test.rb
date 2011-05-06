require 'test_helper'

class Beast::MonitorshipsControllerTest < ActionController::TestCase

  def setup
    School.expects(:find).returns(stub(:id => 1))
    @controller.stubs(:current_user).returns(@user = Staffer.new)
    Monitorship.stubs(:find).returns Monitorship.new
  end

  def test_should_add_monitorship_with_html
    stub_authorization  
    post :create, :scope => 'section', :forum_id => 'forum', :topic_id => 1, :id => 'user'
    assert_redirected_to forum_topic_path(@discussable, 'forum', 1)
  end

  def test_should_deactivate_monitorship_with_html
    stub_authorization 
    delete :destroy, :scope => 'section', :forum_id => 'forum', :topic_id => 1, :id => 'user'
    assert_redirected_to forum_topic_path(@discussable, 'forum', 1)
  end

  def test_should_create
    stub_authorization
    xhr :post, :create, :scope => 'section', :forum_id => 'forum', :topic_id => 1, :id => 'user'
    assert_response :success
  end

  def test_should_deactivate_monitorship
    stub_authorization
    xhr :delete, :destroy, :scope => 'section', :forum_id => 'forum', :topic_id => 1, :id => 'user'
    assert_response :success
  end

  def test_should_require_login_with_html
    stub_authorization(false)
    post :create, :scope => 'section', :forum_id => 'forum', :topic_id => 'topic', :id => 'user'
    assert_redirected_to login_url
  end

  def stub_authorization(return_val = true)
    @controller.expects(:find_or_initialize_discussable).returns(@discussable = mock(:forums => @forums = mock()))
    @forums.expects(:detect).returns(Forum.new)
    @user.expects(:may_access_forum_for?).returns(return_val)
  end
end
