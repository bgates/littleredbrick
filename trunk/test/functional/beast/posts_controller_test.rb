require 'test_helper'

class Beast::PostsControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = Fixtures.identify(:default)
    login_as :aaron
  end

  def test_should_create_reply
    counts = lambda { [Post.count, forums(:rails).posts_count, topics(:pdi).posts_count] }
    equal  = lambda { [forums(:rails).topics_count] }
    old_counts = counts.call
    old_equal  = equal.call

    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :post => { :body => 'blah' }
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :anchor => assigns(:post).dom_id, :page => '1')
    [forums(:rails), users(:aaron), topics(:pdi)].each(&:reload)

    assert_equal old_counts.collect { |n| n + 1}, counts.call
    assert_equal old_equal, equal.call
  end

  def test_should_create_reply_with_xml
    content_type 'application/xml'
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :post => { :body => 'blah' }, :format => 'xml'
    assert_response :created
    assert_equal forum_topic_post_url(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => assigns(:post), :format => :xml), @response.headers["Location"]
  end

  def test_should_update_topic_replied_at_upon_replying
    old=topics(:pdi).replied_at
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :post => { :body => 'blah' }
    assert_not_equal(old, topics(:pdi).reload.replied_at)
    assert old < topics(:pdi).reload.replied_at
  end

  def test_should_reply_with_no_body
    assert_difference 'Post.count', 0 do
      post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => posts(:pdi).id, :post => {}
      assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => posts(:pdi).id, :anchor => 'reply-form', :page => '1')
    end
  end

  def test_should_delete_reply
    counts = lambda { [Post.count, forums(:rails).posts_count, topics(:pdi).posts_count] }
    equal  = lambda { [forums(:rails).topics_count] }
    old_counts = counts.call
    old_equal  = equal.call

    login_as :sam
    delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_reply).id
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails), :id => topics(:pdi))
    [forums(:rails), users(:sam), topics(:pdi)].each(&:reload)

    assert_equal old_counts.collect { |n| n - 1}, counts.call
    assert_equal old_equal, equal.call
  end

  def test_should_delete_and_redirect_to_search
    login_as :sam
    delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_reply).id, :q => 'a search'
    assert_redirected_to posts_path(:scope => forums(:rails).discussable_id, :q => 'a search')
  end

  def test_should_delete_and_redirect_to_see_all
    login_as :sam
    delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_reply).id, :all => true
    assert_redirected_to posts_path(:scope => forums(:rails).discussable_id, :all => true)
  end

  def test_should_delete_reply_with_xml
    content_type 'application/xml'
    logout
    login_as :sam
    delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_reply).id, :format => 'xml'
    assert_response :success
  end

  def test_should_delete_with_js
    login_as :sam
    xhr :delete, :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_reply).id
    assert_response :success
  end
  
  def test_should_delete_reply_as_moderator
    assert_difference 'Post.count', -1 do
      login_as :sam
      delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_rebuttal).id
    end
  end

  def test_should_delete_topic_if_deleting_the_last_reply
    assert_difference 'Post.count', -1 do
      assert_difference 'Topic.count', -1 do
        delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:i18n).id, :id => posts(:i18n).id
        assert_redirected_to forum_path(forums(:rails).discussable_id, forums(:rails))
        assert_raise(ActiveRecord::RecordNotFound) { topics(:i18n).reload }
      end
    end
  end

  def test_can_edit_own_post
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :topic_id => topics(:galactus).id, :id => posts(:silver_surfer).id, :post => {}
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:comics), :id => topics(:galactus), :anchor => posts(:silver_surfer).dom_id, :page => '1')
  end

  def test_can_edit_own_post_with_xml
    content_type 'application/xml'
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :topic_id => topics(:galactus).id, :id => posts(:silver_surfer).id, :post => {}, :format => 'xml'
    assert_response :success
  end


  def test_can_edit_other_post_as_moderator
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_rebuttal).id, :post => {}
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails), :id => posts(:pdi), :anchor => posts(:pdi_rebuttal).dom_id, :page => '1')
  end

  def test_cannot_edit_other_post
    logout
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :topic_id => topics(:galactus).id, :id => posts(:galactus).id, :post => {}
    assert_redirected_to login_url
  end

  def test_cannot_edit_other_post_with_xml
    content_type 'application/xml'
    logout
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :topic_id => topics(:galactus).id, :id => posts(:galactus).id, :post => {}, :format => 'xml'
    assert_response 401
  end

  def test_cannot_edit_own_post_user_id
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_reply).id, :post => { :user_id => 32 }
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails), :id => posts(:pdi), :anchor => posts(:pdi_reply).dom_id, :page => '1')
    assert_equal users(:sam).id, posts(:pdi_reply).reload.user_id
  end

  def test_can_edit_other_post_as_admin
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_rebuttal).id, :post => {}
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails), :id => posts(:pdi), :anchor => posts(:pdi_rebuttal).dom_id, :page => '1')
  end

  def test_fail_update
    Post.expects(:find_by_id_and_topic_id_and_forum_id).returns(@post = Post.new)
    @post.expects(:editable_by?).returns(true)
    @post.stubs(:save).returns false
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_rebuttal).id, :post => {:body => nil}
    assert_redirected_to forum_topic_path(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails), :id => posts(:pdi), :anchor => 'posts-', :page => '1')  
  end
  
  def test_get_edit_form
    get :edit, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_rebuttal).id
    assert_response :success
  end

  def test_get_edit_js
    xhr :get, :edit, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic_id => topics(:pdi).id, :id => posts(:pdi_rebuttal).id
    assert_response :success
  end
  
  def test_should_view_recent_posts
    get :index, :scope => forums(:rails).discussable_id
    assert_response :success
    assert_models_equal [posts(:i18n), posts(:shield_reply), posts(:shield), posts(:silver_surfer), posts(:galactus), posts(:ponies), posts(:pdi_rebuttal), posts(:pdi_reply), posts(:pdi), posts(:sticky)], assigns(:posts)
    #assert_select 'html>head'
  end

  def test_should_view_posts_by_forum
    get :index, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id
    assert_response :success
    assert_models_equal [posts(:shield_reply), posts(:shield), posts(:silver_surfer), posts(:galactus)], assigns(:posts)
    #assert_select 'html>head'
  end

  def test_should_view_posts_by_user
    get :index, :scope => forums(:rails).discussable_id, :reader_id => users(:sam).id
    assert_response :success
    assert_models_equal [posts(:shield), posts(:silver_surfer), posts(:ponies), posts(:pdi_reply), posts(:sticky)], assigns(:posts)
    #assert_select 'html>head'
  end

  def test_should_view_recent_posts_with_xml
    content_type 'application/xml'
    get :index, :scope => forums(:rails).discussable_id, :format => 'xml'
    assert_response :success
    assert_models_equal [posts(:i18n), posts(:shield_reply), posts(:shield), posts(:silver_surfer), posts(:galactus), posts(:ponies), posts(:pdi_rebuttal), posts(:pdi_reply), posts(:pdi), posts(:sticky)], assigns(:posts)
    assert_select 'posts>post'
  end

  def test_should_view_posts_by_forum_with_xml
    content_type 'application/xml'
    get :index, :scope => forums(:comics).discussable_id, :forum_id => forums(:comics).id, :format => 'xml'
    assert_response :success
    assert_models_equal [posts(:shield_reply), posts(:shield), posts(:silver_surfer), posts(:galactus)], assigns(:posts)
    assert_select 'posts>post'
  end

  def test_should_view_posts_by_user_with_xml
    content_type 'application/xml'
    get :index, :scope => forums(:rails).discussable_id, :reader_id => users(:sam).id, :format => 'xml'
    assert_response :success
    assert_models_equal [posts(:shield), posts(:silver_surfer), posts(:ponies), posts(:pdi_reply), posts(:sticky)], assigns(:posts)
    assert_select 'posts>post'
  end

  def test_should_view_monitored_posts
    Monitorship.create(:user_id => users(:aaron).id, :topic_id => topics(:pdi).id, :active => true)
    get :monitored, :scope => forums(:rails).discussable_id, :reader_id => users(:aaron).id
    assert_models_equal [posts(:pdi_reply)], assigns(:posts)
  end

  def test_should_not_view_unmonitored_posts
    get :monitored, :scope => forums(:rails).discussable_id, :reader_id => users(:sam).id
    assert_models_equal [], assigns(:posts)
  end


  def test_should_search_recent_posts
    get :search, :scope => forums(:rails).discussable_id, :q => 'pdi'
    assert_response :success
    assert_models_equal [posts(:pdi_rebuttal), posts(:pdi_reply), posts(:pdi)], assigns(:posts)
  end

  def test_should_search_posts_by_forum
    get :search, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :q => 'galactus'
    assert_response :success
    assert_models_equal [posts(:silver_surfer), posts(:galactus)], assigns(:posts)
  end

  def test_should_view_recent_posts_as_rss
    get :index, :scope => forums(:rails).discussable_id, :format => 'rss'
    assert_response :success
    assert_models_equal [posts(:i18n), posts(:shield_reply), posts(:shield), posts(:silver_surfer), posts(:galactus), posts(:ponies), posts(:pdi_rebuttal), posts(:pdi_reply), posts(:pdi), posts(:sticky)], assigns(:posts)
  end

  def test_should_view_posts_by_forum_as_rss
    get :index, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :format => 'rss'
    assert_response :success
    assert_models_equal [posts(:shield_reply), posts(:shield), posts(:silver_surfer), posts(:galactus)], assigns(:posts)
  end

  def test_should_view_posts_by_user_as_rss
    get :index, :scope => forums(:rails).discussable_id, :reader_id => users(:sam).id, :format => 'rss'
    assert_response :success
    assert_models_equal [posts(:shield), posts(:silver_surfer), posts(:ponies), posts(:pdi_reply), posts(:sticky)], assigns(:posts)
  end

  def test_disallow_new_post_to_locked_topic
    galactus = topics(:galactus)
    galactus.locked = 1
    galactus.save
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :topic_id => topics(:galactus).id, :post => { :body => 'blah' }
    assert_redirected_to forum_topic_path(:forum_id => forums(:comics), :id => topics(:galactus), :page => 1, :anchor => 'reply-form')
    assert_equal '<p>This topic is locked, so no posts may be added.</p>', flash[:error]
  end

  def test_locked_xml
    Topic.any_instance.expects(:locked?).returns(true)
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:comics).id, :topic_id => topics(:galactus).id, :post => { :body => 'blah' }, :format => 'xml'
    assert_response 400
  end
  
  def test_basic_post_url
    setup_url
    posts = forum_topic_post_url(1, 2, 3, 4)
    assert_equal posts, "http://test.host/discussions/1/forums/2/topics/3/posts/4"
    school_posts = forum_topic_posts_url('admin', 2, 3)
    assert_equal school_posts, "http://test.host/discussions/admin/forums/2/topics/3/posts"
  end

  def test_monitored_post_url
    setup_url
    monitored = reader_monitored_posts_url(1,2)
    assert_equal monitored, "http://test.host/discussions/1/members/2/monitored"
    school_monitored = reader_monitored_posts_url('school',2)
    assert_equal school_monitored, "http://test.host/discussions/school/members/2/monitored"
  end

  def test_all_and_search_posts_url
    setup_url
    all = posts_url(2)
    assert_equal all, "http://test.host/discussions/2/posts"
    search_help = search_posts_url('help', :q => 'test')
    assert_equal search_help, "http://test.host/discussions/help/posts/search?q=test"
    assert_routing("/discussions/help/posts/search", { :controller => "beast/posts", :action => "search", :scope => "help", :q => 'test'}, {}, {:q => 'test' })
  end

  def test_basic_and_reader_url
    setup_url
    assert_routing("/discussions/school/forums/2/posts", { :controller => "beast/posts", :action => "index", :scope => "school", :forum_id => '2' })
    teacher_reader = reader_posts_url('teachers',1)
    assert_equal teacher_reader, "http://test.host/discussions/teachers/members/1/posts"
    assert_routing("/discussions/admin/members/2/posts", { :controller => "beast/posts", :action => "index", :scope => "admin", :reader_id => '2' })
  end

  def setup_url
    get :index, :scope => forums(:rails).discussable_id, :user_id => users(:sam).id
  end
end
