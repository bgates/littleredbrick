require 'test_helper'

class Beast::TopicsControllerTest < ActionController::TestCase

  def setup
    @request.session[:school] = Fixtures.identify(:default)
    login_as(:aaron) 
  end

  # page sure we have a special page link back to the last page
  # of the forum we're currently viewing
  def test_should_have_page_link_to_forum
    stub_paginate(:pdi)
    get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    assert_template('show')
  end

  def test_should_show_topic_as_rss
    get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :format => 'rss'
    assert_response :success
    assert_select 'channel'
  end

  def test_should_show_topic_as_xml
    content_type 'application/xml'
    get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :format => 'xml'
    assert_response :success
    assert_select 'topic'
  end

  def test_should_get_new
    get :new, :scope => sections(:beast).id, :forum_id => forums(:rails).id
    assert_response :success
  end

  def test_sticky_and_locked_protected_from_non_admin
    login_as :joe
    assert ! users(:joe).moderator_of?(:rails)
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :sticky => "1", :locked => "1", :first_post => { :body => 'foo' } }
    assert assigns(:topic)
    assert ! assigns(:topic).sticky?
    assert ! assigns(:topic).locked?
  end

  def test_sticky_and_locked_allowed_to_moderator
    login_as :sam
    #assert ! users(:sam).admin?
    assert users(:sam).moderator_of?(forums(:rails))
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :sticky => "1", :locked => "1", :first_post => { :body => 'foo' } }
    assert assigns(:topic)
    assert assigns(:topic).sticky?
    assert assigns(:topic).locked?
  end

  def test_should_allow_admin_to_sticky_and_lock
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :title => 'blah2', :sticky => "1", :locked => "1", :first_post => { :body => 'foo' } }
    assert assigns(:topic).sticky?
    assert assigns(:topic).locked?
  end

  uses_transaction :test_should_not_create_topic_without_body

  def test_should_not_create_topic_without_body
    counts = lambda { [Topic.count, Post.count] }
    old = counts.call

    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :first_post => {}}
    assert assigns(:topic)
    assert assigns(:post)
    # both of these should be new records if the save fails so that the view can
    # render accordingly
    assert assigns(:topic).new_record?
    assert assigns(:post).new_record?

    assert_equal old, counts.call
  end

  def test_should_not_create_topic_without_title
    counts = lambda { [Topic.count, Post.count] }
    old = counts.call

    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :first_post => { :body => 'blah'} }
    #assert_equal "blah", assigns(:topic).body
    assert assigns(:post)
    # both of these should be new records if the save fails so that the view can
    # render accordingly
    assert assigns(:topic).new_record?
    assert assigns(:post).new_record?

    assert_equal old, counts.call
  end

  def test_should_create_topic
    counts = lambda { [Topic.count, Post.count, forums(:rails).topics_count, forums(:rails).posts_count] }
    old = counts.call

    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :first_post => { :body => 'foo' } }
    assert assigns(:topic)
    assert_redirected_to forum_topic_path(forums(:rails).discussable_id, forums(:rails), assigns(:topic))
    [forums(:rails), users(:aaron)].each(&:reload)

    assert_equal old.collect { |n| n + 1}, counts.call
  end

  def test_should_create_topic_with_xml
    content_type 'application/xml'
    post :create, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :first_post => { :body => 'foo' } }, :format => 'xml'
    assert_response :created
    assert_equal forum_topic_url(:scope => forums(:rails).discussable_id, :forum_id => forums(:rails), :id => assigns(:topic), :format => :xml), @response.headers["Location"]
  end

  def test_should_delete_topic
    counts = lambda { [Post.count, forums(:rails).topics_count, forums(:rails).posts_count] }
    old = counts.call

    delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id
    assert_redirected_to forum_path(forums(:rails).discussable_id, forums(:rails))
    [forums(:rails), users(:aaron)].each(&:reload)

    assert_equal old.collect { |n| n - 1}, counts.call
  end

  def test_should_delete_topic_with_xml
    content_type 'application/xml'
    delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id, :format => 'xml'
    assert_response :success
  end

  def test_should_delete_topic_with_js
    xhr :delete, :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id
    assert_response :success
  end
  
  def test_should_allow_moderator_to_delete_topic
    assert_difference 'Topic.count', -1 do
      login_as :sam
      delete :destroy, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    end
  end

  def test_should_update_views_for_show
    login_as :sam
    stub_paginate(:pdi)
    assert_difference 'topics(:pdi).views' do
      get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id
      assert_response :success
      topics(:pdi).reload
    end
  end

  def test_should_not_update_views_for_show_via_rss
    assert_difference 'topics(:pdi).views', 0 do
      get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :format => 'rss'
      assert_response :success
      topics(:pdi).reload
    end
  end

  def test_should_not_add_viewed_topic_to_session_on_show_rss
    get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :format => 'rss'
    assert_response :success
    assert session[:topics].blank?
  end

  def test_should_update_views_for_show_except_redirects
    views=topics(:pdi).views
    stub_paginate(:pdi)
    get :show, {:scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id}, {:school => Fixtures.identify(:default), :user => users(:aaron)}, :ignore => true
    assert_response :success
    assert_equal views, topics(:pdi).reload.views
  end

  def test_should_show_topic
    stub_paginate(:pdi)
    get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    assert_response :success
    assert_equal topics(:pdi), assigns(:topic)
    assert_models_equal [posts(:pdi), posts(:pdi_reply), posts(:pdi_rebuttal)], assigns(:posts)
  end

  def test_should_show_other_post
    stub_paginate(:ponies)
    get :show, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id
    assert_response :success
    assert_equal topics(:ponies), assigns(:topic)
    assert_models_equal [posts(:ponies)], assigns(:posts)
  end

  def test_should_get_edit
    get :edit, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    assert_response :success
  end

  def test_should_update_own_post
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id, :topic => { }
    assert_redirected_to forum_topic_path(forums(:rails).discussable_id, forums(:rails), assigns(:topic))
  end

  def test_should_update_with_xml
    content_type 'application/xml'
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id, :topic => { }, :format => 'xml'
    assert_response :success
  end

  def test_should_not_update_user_id_of_own_post
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:ponies).id, :topic => { :user_id => 32 }
    assert_redirected_to forum_topic_path(forums(:rails).discussable_id, forums(:rails), assigns(:topic))
    assert_equal users(:sam).id, posts(:ponies).reload.user_id
  end

  def test_should_not_update_other_post
    login_as :sam
    put :update, :scope => forums(:comics).discussable_id, :forum_id => forums(:comics).id, :id => topics(:galactus).id, :topic => { }
    assert_redirected_to login_url
  end

  def test_should_not_update_other_post_with_xml
    content_type 'application/xml'
    logout
    login_as :sam #authorize_as :sam the need to login rather than just authorize means xml work isn't possible right now
    put :update, :scope => forums(:comics).discussable_id, :forum_id => forums(:comics).id, :id => topics(:galactus).id, :topic => { }, :format => 'xml'
    assert_response :unauthorized
  end

  def test_should_update_other_post_as_moderator
    login_as :sam
    put :update, :scope => forums(:rails).discussable_id, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :topic => { }
    assert_redirected_to forum_topic_path(forums(:rails).discussable_id, forums(:rails), assigns(:topic))
  end

  protected
  def stub_paginate(topic)
    Post.expects(:paginate_for_topic).returns(@posts = Post.find_all_by_topic_id(topics(topic).id, :include => [{:user => :moderatorships}], :order => "posts.created_at", :conditions => ['posts.discussable_type = ? AND posts.discussable_id = ?', forums(:rails).discussable_type, forums(:rails).discussable_id]))
    @posts.stubs(:total_pages).returns(1); @posts.stubs(:current_page).returns(1)
    Student.any_instance.stubs(:forum_activities).returns([ForumActivity.new(:posts_count => 1)])
    Teacher.any_instance.stubs(:forum_activities).returns([ForumActivity.new(:posts_count => 1)])
    #that's right, STI doesn't catch mocha uses, so each class has to be stubbed
  end
end
