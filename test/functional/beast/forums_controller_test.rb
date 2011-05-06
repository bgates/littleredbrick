require 'test_helper'

class Beast::ForumsControllerTest < ActionController::TestCase

  def setup
    generic_setup(Staffer)
    Section.stubs(:find).with('section id').returns(@section = Section.new)
    @controller.stubs(:find_or_initialize_discussable).returns(@section)
  end

  def test_edit_authorized
    @user.stubs(:owns?).returns(true)
    find_forum
    @proxy.expects(:collect).returns [1] 
    get :edit, :scope => 'staff', :id => 1
    assert_response :success
  end

  def test_index_authorized
    @user.stubs(:may_access_forum_for?).returns(true)
    @user.stubs(:may_create_forum_for?).returns(false) #for view
    get :index, :scope => 'staff'
    assert_response :success
    assert_template('index')
  end
  
  def test_help_index
    @controller.unstub(:find_or_initialize_discussable)
    generic_setup Staffer
    get :index, :scope => 'help'
    assert_template 'index'
    assert_equal('help', assigns(:discussable).type)
  end

  def test_new_authorized
    @user.stubs(:may_create_forum_for?).returns(true)
    get :new, :scope => 'staff'
    assert_response :success
  end

  def test_should_get_index
    @controller.stubs(:authorized?).returns(true)
    @user.expects(:may_create_forum_for?).times(2).returns(true)
    get :index, :scope => 'section id'
    assert_response :success
    assert assigns(:forums)
    assert_equal @section, assigns(:discussable)
    #assert_select 'html>head'
  end

  def test_should_get_new
    @controller.stubs(:authorized?).returns(true)
    get :new, :scope => 'section id'
    assert_response :success
  end

  def test_should_require_admin
    @controller.expects(:authorized?).returns(false)
    get :new, :scope => 'section id'
    assert_redirected_to login_url
  end

  def test_should_create_forum
    @controller.stubs(:authorized?).returns(true)
    create_forum({:name => 'yeah'})
    assert_redirected_to forums_path(@section)
  end

  def test_should_insert_forum_in_list
    proxy_prep
    @forum.expects(:valid?).returns(true)
    @forum.expects(:insert_at).returns(true)
    post :create, :scope => 'section id', :forum => { :name => 'yeah', :position => 'causes insert_at call' }
  end

  def test_fail_create_forum
    proxy_prep
    @forum.expects(:valid?).returns(false)
    post :create, :scope => 'section id', :forum => { :name => '' }
    assert_template('new')
    assert_equal nil, assigns(:forum).id
  end

  def test_should_show_forum
    find_forum
    @user.expects(:owns?).at_least_once.returns(true)
    @user.expects(:may_participate_in?).returns(true)
    Topic.expects(:scoped_by_forum_id).returns []
    get :show, :id => 1, :scope => 'section id'
    assert_response :success
    # sticky should be first
    #assert_equal(topics(:sticky), assigns(:topics).first)
    assert_select 'html>head'
  end

  def test_should_get_edit
    find_forum
    @proxy.stubs(:detect).returns(@forum = Forum.new(:name => 'test'))
    @proxy.stubs(:collect).returns([])
    @user.expects(:owns?).returns(false)
    get :edit, :id => 1, :scope => 'section id'
    assert_response :success
  end

  def test_should_update_forum
    prep_update
    put :update, :id => 1, :scope => 'section id', :forum => { }
    assert_redirected_to forums_path(@section)
  end

  def test_should_destroy_forum
    find_forum
    @forum.expects(:destroy).returns(true)
    delete :destroy, :id => 1, :scope => 'section id'
    assert_redirected_to forums_path(@section)
  end

  def test_personal_url
    @controller.stubs(:authorized?).returns(true)
    @school.expects(:id).at_least_once.returns(@request.session[:school])
    School.expects(:find).with(@request.session[:school]).returns(@school)
    @controller.expects(:find_or_initialize_discussable).with(nil).returns nil
    get :index
    personal = personal_url
    assert_equal personal, "http://test.host/discussions"
    assert_routing("/discussions", { :controller => "beast/forums", :action => "index" })
    assert_template('personal')
  end

  private

  def proxy_prep
    @controller.stubs(:authorized?).returns(true)
    @user.expects(:owned_forums).returns(@proxy = mock('association proxy'))
    @proxy.expects(:create).returns(@forum = Forum.new)
  end

  def create_forum(params)
    proxy_prep
    @forum.expects(:insert_at).returns(true)
    @forum.expects(:valid?).returns(true)
    post :create, :scope => 'section id', :forum => params
  end

  def find_forum
    @controller.stubs(:authorized?).returns(true)
    @section.expects(:forums).at_least_once.returns(@proxy = mock('association proxy'))
    @proxy.stubs(:detect).returns(@forum = Forum.new(:name => 'test'))
    @proxy.stubs(:find).returns @forum
  end

  def prep_update
    find_forum
    @forum.expects(:update_attributes!)
    @forum.expects(:insert_at)
  end

end
