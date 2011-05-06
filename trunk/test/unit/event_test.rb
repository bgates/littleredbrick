require 'test_helper'
class EventTest < Test::Unit::TestCase

  def test_valid
    @event = Event.new(:creator_id => 1, :date => Date.today, :name => 'first', :description => 'just for the test', :invitable_type => 'User', :invitable_id => 1)
    assert @event.valid?
    assert_equal Date.today.month, @event.month
    assert_equal Date.today.year, @event.year
  end

  def test_audience_personal
    @event = Event.new(:invitable_type => 'User')
    User.expects(:find).returns(Teacher.new)
    assert_equal 'no one but you', @event.audience
  end

  def test_audience_personal_for_students
    @event = Event.new(:invitable_type => 'User')
    User.expects(:find).returns(Student.new)
    assert_equal 'you and your parents', @event.audience
  end

  def test_audience_section
    Section.expects(:find).with(400).returns(stub(:time => 4, :name => 'test'))
    @event = Event.new(:invitable_type => 'Section', :invitable_id => 400)
    assert_equal 'everyone in your period 4 test class', @event.audience
  end

  def test_audience_section_full_coverage
    Section.expects(:find).with(400).returns(stub(:time => nil, :name => 'test'))
    @event = Event.new(:invitable_type => 'Section', :invitable_id => 400)
    assert_equal 'everyone in your test class', @event.audience
  end

  def test_viewable_by_staff
    @user = Staffer.new(:school_id => 12)
    @event = Event.new(:invitable_type => 'Staff', :invitable_id => 12)
    assert @event.viewable_by?(@user)
    assert !@event.viewable_by?(Staffer.new(:school_id => 404))
    assert !@event.viewable_by?(Student.new(:school_id => 12))
  end

  def test_viewable_by_section
    @user = User.new
    @user.expects(:section_ids).returns([1, 10])
    @event = Event.new(:invitable_type => 'Section', :invitable_id => 10)
    assert @event.viewable_by?(@user)
    @other_user = User.new
    @other_user.expects(:section_ids).returns([1, 100])
    assert !@event.viewable_by?(@other_user)
  end

  def test_editability
    @user = mock(:id => 1)
    assert Event.new(:creator_id => 1).editable_by?(@user)
  end

  def test_viewable_by_self
    @user = User.new
    @user.expects(:id).returns 1
    assert Event.new(:creator_id => 1, :invitable_type => 'User').viewable_by?(@user)
  end

  def test_viewable_by_school
    @user = mock(:school_id => 2)
    assert Event.new(:invitable_type => 'School', :invitable_id => 2).viewable_by?(@user)
  end

  def test_viewable_by_teacher
    @user = Teacher.new(:school_id => 3)
    assert Event.new(:invitable_type => 'Teachers', :invitable_id => 3).viewable_by?(@user)
  end
end

