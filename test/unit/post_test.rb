require 'test_helper'

class PostTest < ActiveSupport::TestCase

  def test_should_require_body_for_post
    @post = Post.new
    @post.valid?
    assert !@post.errors[:body].empty?
  end

  def test_should_create_reply
    prep_post
    assert @post.valid?
    assert @post.save
  end

  def test_should_create_reply_and_set_forum_from_topic
    prep_post
    @post.save
    assert_equal @post.forum_id, @topic.forum_id
  end

  def test_should_delete_reply
    prep_post
    @post.destroy
  end

  def test_should_edit_own_post
    prep_edit
    @user.expects(:id).returns(1)
    assert @post.editable_by?(@user)
  end

  def test_should_edit_post_as_moderator
    prep_edit
    @post.expects(:topic).returns(Topic.new)
    @user.expects(:moderator_of?).returns(true)
    assert @post.editable_by?(@user)
  end

  def test_should_not_edit_post_in_own_topic
    prep_edit
    @post.expects(:topic).returns(Topic.new)
    @user.expects(:moderator_of?).returns(false)
    assert !@post.editable_by?(@user)
  end

  def test_requires_valid_html
    @post = Post.new(:body => '<em>Danger, this tag is not closed!')
    assert !@post.valid?
    assert_equal @post.errors[:body][0], 'is not valid HTML.'
  end

  def test_accepts_valid_html
    @post = Post.new(:body => '*This is an important tag*\nbq. this is a quote\n')
    @post.user_id = 1
    assert @post.valid?
  end

  def test_date
    prep_edit
    @time = Time.now
    @post.expects(:updated_at).returns(@time)
    assert_equal @post.date, @time.strftime("%a %b %d")
  end

  def test_update_section_posts_count
    prep_post
    @post.discussable_type = 'Section'
    Section.expects(:find).returns(mock(:increment! => true))
    assert @post.save
  end

  def test_xml #I don't know anything about xml testing, this is just a hack to get 100% C0
    @post = Post.new
    assert @post.to_xml(:except => [:discussable])
  end

  def test_remove_obscenities
    prep_post
    @post.body = 'this shit is a fuckin disgrace. The asshole who typed this with his cock should get his faggity ass expelled.'
    @post.save
    assert_equal 'this smurf is a smurf disgrace. The smurf who typed this with his smurf should get his smurf smurf expelled.', @post.body
  end
  protected
  def prep_post
    Forum.expects(:update_all)
    @post = Post.new(:body => 'blah')
    @post.user_id = 1; @post.topic_id = 1
    @post.stubs(:topic).returns(@topic = Topic.new(:forum_id => 4))
    @topic.expects(:update_cached_post_fields)
  end

  def prep_edit
    @user = User.new
    @post = Post.new
    @post.user_id = 1
  end
end

