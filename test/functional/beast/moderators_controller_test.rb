require 'test_helper'

class Beast::ModeratorsControllerTest < ActionController::TestCase

  def setup
    generic_setup(Staffer)
    @controller.stubs(:find_or_initialize_discussable).returns(@section = Section.new)
    @section.stubs(:name).returns('Test class')
    @section.stub_path('forums.find').returns(@forum = Forum.new(:name => 'for helper'))
    @controller.stubs(:by_user).returns('staffer')
    @user.stubs(:id).returns('user id')
    @forum.stubs(:owner_id).returns('user id')
  end

  def test_should_delete_moderatorship
    stub_delete
    delete :destroy, :scope => 'section id', :user_id => 'user id', :forum_id => 'forum id', :id => 'not user id'
    assert_redirected_to reader_path(@section, @user)
  end

  def test_delete_xhr
    stub_delete
    xhr :delete, :destroy, :scope => 'section id', :user_id => 'user id', :forum_id => 'forum id', :id => 'not user id'
    assert_response :success
  end
  
  def test_should_not_delete_own_moderatorship
    stub_find
    @mod.stubs(:user_id).returns('user id')
    delete :destroy, :scope => 'section id', :user_id => 'user id', :forum_id => 'forum id', :id => 'user id'
    assert flash[:error]
  end

  def test_should_only_allow_admins_to_delete_moderatorships
    @controller.expects(:authorized?).returns(false)
    delete :destroy, :scope => 'section id', :user_id => 'user id', :forum_id => 'forum id', :id => 'user id'
    assert_redirected_to login_url
  end

  def test_should_not_allow_setting_admin_with_xml
    try_to_create(:format => 'xml')
    assert_response 406
  end

  def test_should_add_moderator_from_reader_page
    try_to_create(:return => true)
    assert_redirected_to reader_path(@section, @user)
  end

  def test_should_add_moderator_from_index
    try_to_create
    assert_redirected_to forum_moderators_path(@section, @forum)
  end

  def test_should_create_moderator_with_js
    stub_create
    xhr :post, :create, :scope => 'section id', :forum_id => 'forum id', :id => 'id'
    assert_response :success
  end
  
  def test_should_update_moderator_and_return_to_index
    @forum.moderatorships.expects(:update_list).with([1, 3, 4])
    put :update, {:scope => 'section id', :forum_id => 'forum id', :id => 'id', :moderator => {'1' => 'true', '3' => 'true', '4' => 'true'}, :forum => 'forum id'}
    assert_redirected_to forum_moderators_path(@section, @forum)
  end

  def test_should_require_admin_to_set_admin_properties
    @controller.expects(:authorized?).returns(false)
    try_to_create
    assert_redirected_to login_url
  end

  def test_index
    get :index, :scope => 'section id', :forum_id => 'forum id'
    assert_template('index')
  end

  def test_search_single_result
    prep_search
    stub_create
    get :search, :search => 'query', :scope => 'section id', :forum_id => 'forum id'
    assert_redirected_to forum_moderators_path(@section, @forum)
  end

  def test_search_xhr
    prep_search
    xhr :get, :search, :scope => 'section id', :forum_id => 'forum id', :search => 'query'
    assert_template('search_results')
  end

  def test_search_no_result
    prep_search([])
    get :search, :search => 'query', :scope => 'section id', :forum_id => 'forum id'
    assert_redirected_to forum_moderators_path(@section, @forum)
  end

  def test_search_multiple_results
    prep_search([User.new, User.new])
    get :search, :search => 'query', :scope => 'section id', :forum_id => 'forum id'
    assert_template 'new'
  end
  protected

  def prep_search(result = [User.new])  
    @school.stubs(:id).returns('id')
    Moderatorship.expects(:search).with('query', :school_id => 'id', :discussable => @section).returns(result)
  end
  
  def try_to_create(options = {})
    stub_create
    post :create, {:scope => 'section id', :forum_id => 'forum id', :user => {:id => 'user id'}, :forum => ['forum id']}.merge(options)
  end

  def stub_create 
    @forum.stub_path('members.find').returns(@user = Staffer.new)
    @user.stub_path('moderatorships.create').returns(Moderatorship.new)
  end
  
  def stub_delete
    stub_find
    @mod.stubs(:user_id).returns('not user id')
    @mod.expects(:destroy).returns(true)
    @owner.stubs(:id).returns('not user id')
  end

  def stub_find  
    @forum.stub_path('moderatorships.find').returns(@mod = Moderatorship.new)
    @mod.stubs(:user).returns(@owner = Staffer.new)
  end

end
