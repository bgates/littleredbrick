require 'test_helper'

class StafferTest < Test::Unit::TestCase

  def setup
    @staffer = Staffer.new
  end

  def test_admin
    assert @staffer.admin?
  end

  def test_may_access_and_create_forums
    %w(admin help parents school staff).each do |scope|
      discussable = School.new
      discussable.type = scope
      assert @staffer.may_access_forum_for?(discussable)
      assert @staffer.may_create_forum_for?(discussable) || scope == 'help'
    end
  end

  def test_may_not_access_or_create_other_forums
    school = School.new
    school.type = 'teachers'
    assert !@staffer.may_access_forum_for?(school)
    assert !@staffer.may_create_forum_for?(Section.new)
  end

  def test_display
    @staffer.last_name = 'Smith'
    assert_equal 'Smith', @staffer.display_name

    @staffer.title = 'Mr'
    assert_equal 'Mr Smith', @staffer.display_name
  end

  def test_may_see
    [Section.new, Teacher.new].each do |whatever|
      assert @staffer.may_see?(whatever)
    end
  end

  def test_events
    @staffer.expects(:school).returns(mock(:current_term => mock(:tracks => [Track.new])))
    @staffer.stubs(:id).returns(1)
    @staffer.stubs(:school_id).returns(100)
    @personal_event = Event.create(:name => 'personal', :invitable_type => 'User', :invitable_id => 1, :date => Date.today)
    @staff_event = Event.create(:name => 'staff meeting', :invitable_type => 'Staff', :invitable_id => 100, :date => Date.today + 3, :creator_id => 2)
    @event_made_for_teachers = Event.create(:name => 'some teacher thing', :invitable_type => 'Teachers', :invitable_id => 100, :date => Date.today + 4, :creator_id => 1)
    @distant_future = Event.create(:name => 'in the future', :invitable_type => 'Staff', :invitable_id => 100, :date => Date.today + 100, :creator_id => 1)
    assert_equal [@personal_event, @staff_event, @event_made_for_teachers], @staffer.all_events(Date.today, Date.today + 5)
  end
end

