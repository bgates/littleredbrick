require 'test_helper'
require 'helper_test_helper'

class Beast::ForumsHelperTest < ActionView::TestCase

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_suffix
    assert_equal(', as well as for each of your classes', and_classes_if_teacher)
  end

  def test_examples
    discussable = stub(:klass => 'school')
    assert new_examples_for(discussable) =~ /sports/
    discussable.stubs(:klass).returns 'admin'
    assert new_examples_for(discussable) =~ /sick/
    discussable.stubs(:klass).returns 'staff'
    assert new_examples_for(discussable) =~ /professional/
    discussable.stubs(:klass).returns 'parents'
    assert new_examples_for(discussable) =~ /graduation/
    discussable.stubs(:klass).returns 'teachers'
    assert new_examples_for(discussable) =~ /union/
  end

  def test_post_data
    post = Post.new
    post.forum_id, post.topic_id = 1, 2
    time = Time.now
    post.stubs(:created_at).returns time
    post.stub_path('topic.posts_count').returns 55
    post.stub_path('user.display_name').returns 'last writer'
    post.stubs(:body).returns 'here is the post'
    school = School.new
    school.stubs(:id).returns 'school'
    result = link_to time.strftime('%b %d'), forum_topic_path(school, 1, 2, :page => 3), :title => 'last writer: here is the post'
    assert_equal(result, post_data(post, school))
  end

  def test_no_recent_activity
    self.expects(:logged_in?).returns true
    result = image_tag 'comment.gif', :class => 'icon grey',
                                      :title => 'No recent activity'
    assert_equal(result, recent_activity_indicator(Forum.new))
  end

  def test_recent_activity
    self.expects(:logged_in?).returns true
    time = Time.now
    self.expects(:last_active).returns time - 5
    forum = Forum.new
    forum.stubs(:posts).returns [stub(:created_at => time)]
    session[:forums] = {}
    result = image_tag 'comment.gif', :class => 'icon highlight',
                                      :title => 'This forum has had recent activity'
    assert_equal(result, recent_activity_indicator(forum))
  end

  def test_recent_topic_activity
    time = Time.now
    self.expects(:last_active).returns time - 5
    topic = mock(:locked => true, :replied_at => time, :id => 'id')
    session[:topics] = {}
    result = image_tag 'lock.gif', :class => 'icon highlight', :title => 'Recent activity, this topic is locked.'
    assert_equal(result, recent_topic_activity_indicator(topic))
  end
end

