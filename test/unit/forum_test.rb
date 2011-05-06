require 'test_helper'

class ForumTest < ActiveSupport::TestCase

  def test_should_create_position
    forum = Forum.new(:name => 'new', :discussable_type => "Section", :discussable_id => 1, :owner_id => 1)

    forum.save
    assert forum.valid?
    assert_not_nil forum.position
  end

  def test_should_create_with_empty_position
    forum = Forum.create(:name => 'new', :discussable_type => "Section", :discussable_id => 1, :position => '', :owner_id => 1)
    assert forum.valid?
    assert_not_nil forum.position
  end

  def test_should_format_body_html
    forum = Forum.new(:description => 'foo')
    forum.send :format_content
    assert_not_nil forum.description_html

    forum.description = ''
    forum.send :format_content
    assert forum.description_html.blank?
  end

  def test_membership_section_forum
    @forum = Forum.new(:discussable_type => 'Section', :discussable_id => 1)
    Section.expects(:find).with(1).returns mock(:teacher_id => 'teacher', :student_ids => [1, 2, 3])
    result = "SELECT \"users\".* FROM \"users\" WHERE ((users.type = 'Teacher' AND users.id = teacher) OR (users.type = 'Student' AND users.id IN (1,2,3)))"
    assert_equal @forum.send(:member_conditions), result
  end

  def test_membership_school_forum
    @forum = Forum.new(:discussable_type => 'school', :discussable_id => 1)
    result = "SELECT \"users\".* FROM \"users\" WHERE school_id = 1"
    assert_equal @forum.send(:member_conditions), result
  end

  def test_membership_help_forum
    @forum = Forum.new(:discussable_type => 'help', :discussable_id => 'immaterial')
    result = "SELECT \"users\".* FROM \"users\" WHERE type = 'Teacher' OR type = 'Staffer' OR type = 'G'"
    assert_equal @forum.send(:member_conditions), result
  end

  def test_membership_teachers_forum
    @forum = Forum.new(:discussable_type => 'teachers', :discussable_id => 1)
    result = "SELECT \"users\".* FROM \"users\" WHERE school_id = 1 AND type = 'Teacher'"
    assert_equal @forum.send(:member_conditions), result
  end

  def test_membership_staff_forum
    @forum = Forum.new(:discussable_type => 'staff', :discussable_id => 1)
    result = "SELECT \"users\".* FROM \"users\" WHERE school_id = 1 AND (type = 'Teacher' OR type = 'Staffer')"
    assert_equal @forum.send(:member_conditions), result
  end

  def test_membership_admin_forum
    @forum = Forum.new(:discussable_type => 'admin', :discussable_id => 1)
    result = "SELECT \"users\".* FROM \"users\" WHERE school_id = 1 AND type = 'Staffer'"
    assert_equal @forum.send(:member_conditions), result
  end

end

