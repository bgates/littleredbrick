require 'test_helper'

class TopicTest < Test::Unit::TestCase

  def setup
    @topic = Topic.new
  end

  def test_should_require_title_user_and_forum
    @topic.valid?
    assert !@topic.errors[:title].empty?
    assert !@topic.errors[:user_id].empty?
    assert !@topic.errors[:forum_id].empty?
    assert ! @topic.save
    make_valid
    assert @topic.valid?
  end

  def test_replied_at_set
    @topic.user_id = 1
    @topic.title = "happy life"
    @topic.forum_id = 2
    @topic.expects(:forum).returns(mock(:open => true))
    @topic.expects(:update_forum_counter_cache).returns(true)
    assert @topic.save
    assert_not_nil @topic.replied_at
    assert @topic.replied_at <= Time.now.utc
    assert_in_delta @topic.replied_at, Time.now.utc, 5.seconds
  end

  def test_should_return_correct_last_page
    @topic.posts_count = 51
    assert_equal 3, @topic.last_page
    @topic.posts_count = 26
    assert_equal 2, @topic.last_page
    @topic.posts_count = 1
    assert_equal 1, @topic.last_page
    @topic.posts_count = 0
    assert_equal 1, @topic.last_page
  end

  def test_closed_forum_only_lets_owner_create_topics
    forum_id = 1; owner_id = 2
    Forum.expects(:find).returns(Forum.new(:owner_id => owner_id, :open => false, :discussable_id => 1, :discussable_type => 'School'))
    @topic.user_id = 3
    @topic.title = "will fail"
    @topic.forum_id = forum_id
    assert !@topic.save
    @topic.user_id = owner_id
    assert @topic.save
  end

  def test_counter_cache
    prep_counter('non-section')
    make_valid
    assert @topic.save
  end

  def test_counter_cache_section
    prep_counter('Section')
    make_valid
    Section.expects(:find).with(1).returns(@section = Section.new)
    @section.expects(:increment!).with(:topics_count)
    assert @topic.save
  end

  def test_editable_by_owner
    prep_editor
    @user.expects(:id).returns(1)
    assert @topic.editable_by?(@user)
  end

  def test_editable_by_moderator
    prep_editor
    @topic.expects(:forum).returns(@forum = mock())
    @user.expects(:moderator_of?).with(@forum).returns(true)
    assert @topic.editable_by?(@user)
  end

  def test_not_editable
    prep_editor
    assert !@topic.editable_by?(@user)
  end

  def test_hit
    Topic.expects(:increment_counter).with(:hits,  'id').returns(true)
    @topic.expects(:id).returns('id')
    assert @topic.hit!
  end

  def test_cached_fields
    @post = mock(:frozen? => true)
    @topic.expects(:posts_count).returns(1)
    @topic.expects(:destroy)
    @topic.update_cached_post_fields(@post)
  end

  def test_cached_fields_last_post
    Topic.expects(:update_all).with(['replied_at = ?, replied_by = ?, last_post_id = ?, posts_count = ?', Date.today, 'user_id', 'post_id', 0], ['id = ?', 'id'])
    @post = stub(:created_at => Date.today, :user_id => 'user_id', :id => 'post_id')
    @topic.stubs(:id).returns('id')
    @topic.update_cached_post_fields(@post)
  end

  def test_first_post
    @topic.forum_id = 4
    @topic.first_post = {:body => 'for post and topic'}
    assert_equal 1, @topic.posts.length
    assert_equal 4, @topic.posts.first.forum_id
    assert_equal 'for post and topic', @topic.body
  end

  def test_save_with_changed_forum
    make_valid
    @topic.expects(:set_default_replied_at_and_sticky).returns(true)
    @topic.stubs(:set_section_topic_count).returns(true)
    @topic.save
    @topic.forum_id = 10
    Topic.expects(:where).with(["forum_id = ?", 2]).returns mock(:count => 100)
    Post.expects(:where).with(["forum_id = ?", 2]).returns mock(:count => 1000)
    Forum.expects(:update_all).with(['topics_count = ?, posts_count = ?', 100, 1000], ['id = ?', 2])
    Post.expects(:where).with(["forum_id = ?", 10]).returns mock(:count => 1)
    Forum.expects(:update_all).with(['topics_count = ?, posts_count = ?', 1, 1], ['id = ?', 10])
    @topic.save
  end
  protected
  def make_valid
    @topic.user_id  = 1
    @topic.title = "happy life"
    @topic.forum_id = 2
  end

  def prep_counter(type)
    Topic.expects(:count).with(:id, :conditions => "forum_id = 2").returns('n')
    Forum.expects(:update_all).with(['topics_count = ?', 'n'], ['id = ?', 2])
    @topic.stubs(:forum).returns(Forum.new(:discussable_id => 1, :discussable_type => type, :open => true))
  end

  def prep_editor
    @topic.user_id = 1
    @user = User.new
  end
end

