require 'test_helper'

class ModeratorshipTest < ActiveSupport::TestCase

  def test_should_add_moderator_not_duplicate
    assert_difference 'Moderatorship.count' do
      Moderatorship.create(:user_id => 1, :forum_id => 1)
    end

    assert_difference 'Moderatorship.count', 0 do
      Moderatorship.create(:user_id => 1, :forum_id => 1)
    end
  end

  def test_search_school
    User.expects(:search).with('query', :school_id => 'school')
    moderator_search('school')
  end
  #note that params[:discussable] is expected to be a Discussable, with a #klass
  def test_search_section
    @section = Section.new
    @students = @section.students
    @students.expects(:where).with(['LOWER(last_name) ILIKE :q OR LOWER(first_name) ILIKE :q', {:q => 'name%'}])
    Moderatorship.search('name', :discussable => @section)
  end

  def test_search_parents
    expect_search(Parent)
    expect_search(Staffer)
    expect_search(Teacher)
    moderator_search('parents')
  end

  def test_search_teachers
    expect_search(Teacher)
    moderator_search('teachers')
  end

  def test_search_staff
    expect_search(Staffer)
    expect_search(Teacher)
    moderator_search('staff')
  end

  def test_search_admin
    Staffer.expects(:search).with('query', :school_id => 'school', :conditions => ["type <> 'Teacher'"])
    Moderatorship.search('query', :school_id => 'school', :discussable => mock(:klass => 'admin'))
  end
  protected
  def expect_search(klass)
    klass.expects(:search).with('query', :school_id => 'school').returns([])
  end

  def moderator_search(discussable)
    Moderatorship.search('query', :school_id => 'school', :discussable => mock(:klass => discussable))
  end
end

