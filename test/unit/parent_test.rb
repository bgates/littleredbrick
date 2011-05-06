require 'test_helper'

class ParentTest < ActiveSupport::TestCase

  def setup
    @mom = Parent.new
  end

  def test_next_id
    max = mock(:maximum => 100)
    Parent.expects(:where).with(['school_id = ?', :school]).returns max
    assert_equal(101, Parent.next_id_number(:school))
  end
 
  def all_child_events(start, finish, include_assignments, child)
    child ? child.all_events(start, finish, include_assignments) : []
  end

  def test_child_events
    assert_equal(@mom.all_child_events(:today, :tomorrow, false, nil), [])
    child = Student.new
    child.expects(:all_events).with(:today, :tomorrow, false).returns :event
    assert_equal(:event, 
                 @mom.all_child_events(:today, :tomorrow, false, child))
  end
 
  def test_ensure_new_children
    assert_equal(2, @mom.ensure_new_children.length)
    assert @mom.ensure_new_children.each{|child| child.is_a? Student }
  end

  def test_ensure_no_more_children
    @mom.children.build Student.new
    assert_equal([], @mom.ensure_new_children)
  end

  def test_remove_new_id_numbers
    @mom.children << student = Student.new(:id_number => 1)
    student.stubs(:new_record?).returns false
    assert_equal([1, nil, nil], 
                 @mom.existing_and_new_children.map(&:id_number))
  end

  def test_parent_ids
    @mom.expects(:children).returns [mock(:parent_ids => [1,2]), 
                                     mock(:parent_ids => [3,4])]
    assert_equal([1,2,3,4], @mom.fellow_parent_ids)
  end
 
  def test_no_invalid_children
    @mom.expects(:children).returns [stub(:valid? => true), 
                                     stub(:valid? => true)] 
    assert ! @mom.has_invalid_children?
  end

  def test_destroy
    prep_destroy(2)
    assert @mom.destroy
  end

  def test_all_events
    parent = Parent.new
    parent.stubs(:id).returns 'id'
    start, finish = Date.today, Date.today + 1
    Event.expects(:where).with(["invitable_type = 'User' AND invitable_id = ? AND date BETWEEN ? AND ?", 'id', start, finish]).returns ['events']
    assert_equal(parent.all_events(start, finish), ['events'])
  end

  def test_all_recent_posts
    first = Time.now
    topic1_post1 = stub(:topic_id => 1, :created_at => first)
    topic1_post2 = stub(:topic_id => 1, :created_at => first - 1.hour)
    topic2_post1 = stub(:topic_id => 2, :created_at => first - 3.hours)
    Post.stub_path('where.includes').returns([topic1_post1, topic1_post2, topic2_post1])
    #result = {1 => }
  end
  #def test_destroy_replace
  #  prep_destroy
  #  @student.expects(:add_parents)
  #  assert @mom.destroy
  #end

  def test_update_with_new_child
    prep_parent(1)
    @parent.expects(:replace_old_parent_of).returns(true)
    assert @parent.children.all?{|c| c.valid?}
    assert @parent.valid?
  end

  def test_fail_update_with_duplicate_children
    prep_parent(2)
    @student.id_number = 'no match'
    @parent.valid?
    assert @parent.errors[:base][0] =~ /There are 2/
  end

  def test_fail_update_with_nonexistent_child
    prep_parent(0)
    @parent.valid?
    assert @parent.errors[:base][0] =~ /I can't find/
  end

  def test_should_replace_parent
    prep_replace
    @parents.expects(:includes).returns(@placeholder = Parent.new)
    assert @parent.should_replace_parent_of(@kid, @match)
  end

  def test_should_not_replace_logged_in_parent
    prep_replace
    @parents.expects(:includes).returns(stub(:where => stub(:first => @placeholder = Parent.new)))
    @placeholder.expects(:never_logged_in?).returns(false)
    assert !@parent.should_replace_parent_of(@kid, @match)
  end

  def test_should_not_replace_unmatched_parent
    prep_replace
    @parents.expects(:includes).returns(stub(:where => stub(:first => nil)))
    assert !@parent.should_replace_parent_of(@kid, @match)
  end

  def test_does_not_replace_parent
    @parent = Parent.new(:gender => 'mother')
    @parent.expects(:should_replace_parent_of).returns(false)
    @parent.replace_old_parent_of(Student.new, Student.new)
    assert @parent.errors[:base][0] =~ /Someone else has already logged on as mother for/
  end

  def test_does_replace_parent
    prep_replace
    @parents.expects(:includes).returns(stub(:where => stub(:first => (@replacement = Parent.new))))
    Parent.expects(:destroy).with(@replacement)
    assert @parent.replace_old_parent_of(@kid, @match)
    assert_equal [@match], @parent.children
  end

  def test_may_access_parent_forum
    @discussable = mock('discussion group')
    @discussable.expects(:klass).at_least_once.returns('parents')
    @parent = Parent.new
    assert @parent.may_access_forum_for?(@discussable)
    assert !@parent.may_create_forum_for?(@discussable)
  end

  def test_may_not_access_or_create_other_forums
    @parent = Parent.new
    %w(Section staff admin teachers help).each do |klass|
      discussable = mock(klass)
      discussable.stubs(:klass).returns(klass)
      assert !@parent.may_access_forum_for?(discussable)
      assert !@parent.may_create_forum_for?(discussable)
    end
  end

  def test_may_join_forums
    parent = Parent.new
    discussable = stub(:klass => 'parents')
    assert parent.may_participate_in?(discussable)
    discussable.stubs(:klass).returns 'school'
    assert !parent.may_participate_in?(discussable)
  end
  #def test_prevent_orphan
  #  @orphan, @child = Student.new, Student.new
  #  stub_parent([@orphan, @child])
  #  @orphan.expects(:parents).returns(mock(:count => 1))
  #  @orphan.expects(:add_parents)
  #  @child.expects(:parents).returns(mock(:count => 2))
  #  @parent.prevent_orphan
  #end

  def test_replacements
    @school = School.new
    stub_parent([@child = Student.new])
    @parent.build_authorization(:login => 'test_father')
    @logged_in, @replacement = Student.new, Student.new
    @replacement.expects(:parent_login_checked?).with('_father').returns(false)
    @school.students.expects(:where).returns([@child, @logged_in, @replacement])
    assert_equal [@replacement], @parent.replacements('query', @school)
  end

  def test_existing_children
    stub_parent([@existing = Student.new, @new_child = Student.new])
    @existing.stubs(:new_record?).returns(false)
    @existing.stubs(:id).returns(1)
    Student.any_instance.stubs(:school).returns School.new
    @parent.existing_child_attributes = {'1' => {:first_name => 'test', :last_name => 'child'}}
    assert_equal 'test child', @existing.full_name
  end

  def test_delete_existing_children
    @children = [@no_attr = Student.new, @empty_attr = Student.new]
    stub_parent(@children)
    Student.any_instance.stubs(:new_record?).returns(false)
    @empty_attr.stubs(:id).returns(1)
    @children.each{|child| @children.expects(:delete).with(child)}
    @parent.existing_child_attributes = {'1' => {}}
  end

  def test_new_child
    @parent = Parent.new(:school_id => 1)
    @parent.new_child_attributes = [{:first_name => 'test'}, {:grade => 9}]
    assert_equal 1, @parent.children.length
    assert_equal 'test', @parent.children.first.first_name
  end

  def test_add_correctly_skips_existing_child
    stub_parent
    @child.expects(:new_record?).returns(false)
    @parent.send :new_children_added_correctly
    assert @parent.errors.empty?
  end

  def test_fail_add_child_not_in_db
    stub_parent
    @parent.expects(:get_matches_for).returns([])
    @parent.send :new_children_added_correctly
    assert !@parent.errors[:base].blank?
  end

  def test_replace_parent
    stub_parent
    @parent.expects(:get_matches_for).returns([@student = Student.new])
    @parent.expects(:replace_old_parent_of).with(@child, @student)
    @parent.send :new_children_added_correctly
    assert @parent.errors.empty?
  end

  def test_fail_add_child_who_shares_name
    stub_parent
    @parent.expects(:get_matches_for).returns([@student = Student.new(:id_number => 'exist'), @other = Student.new(:id_number => 'exist')])
    @parent.send :new_children_added_correctly
    assert !@parent.errors[:base].blank?
  end

  def test_add_child_if_id_matches
    stub_parent
    @child.id_number = 'match'
    @parent.expects(:get_matches_for).returns([@student = Student.new(:id_number => 'match'), @other = Student.new(:id_number => 'no match')])
    @parent.expects(:replace_old_parent_of).with(@child, @student)
    @parent.send :new_children_added_correctly
    assert @parent.errors.empty?
  end

  def test_replace_old_parent
    stub_parent
    @parent.expects(:should_replace_parent_of).returns(@replacement = Parent.new)
    Parent.expects(:destroy).with(@replacement)
    @kid = Student.new
    @parent.replace_old_parent_of(@child, @kid)
    assert_equal [@kid], @parent.children
  end

  def test_fail_replace_parent
    stub_parent
    @parent.gender = 'father'
    @child.full_name = 'test child'
    @parent.replace_old_parent_of(@child, @kid = Student.new)
    assert_equal [@child], @parent.children
    assert !@parent.errors[:base].blank?
  end

  def test_should_replace_parent
    stub_parent
    @parent.gender = 'father'
    @child.full_name = 'test child'
    @kid = Student.new
    @kid.parents.expects(:includes).returns(stub(:where => stub(:first => Parent.new)))
    assert @parent.should_replace_parent_of(@child, @kid)
  end

  def test_display_name
    @parent = Parent.new(:first_name => 'Jeff', :last_name => 'Goldblum')
    assert_equal 'Jeff Goldblum', @parent.display_name
    @parent.title  = 'Mr'
    assert_equal 'Mr Goldblum', @parent.display_name
  end

  def test_which_parent
    @parent = Parent.new(:last_name => '_father')
    assert_equal @parent.which_parent, 'father'
  end

  def test_matches
    @parent = Parent.new(:school_id => 1)
    @parent.stub_path('school.students.where').returns []
    @kid = mock(:first_name => 'test', :last_name => 'name', :grade => 11)
    assert_equal [], @parent.send(:get_matches_for, @kid)
  end
  protected

  def prep_replace
    @parent = Parent.new(:gender => 'mother')
    @kid = @match = Student.new(:first_name => 'find_a', :last_name => 'match')
    @parents = @match.parents
  end

  def prep_parent(n)
    @parent = Parent.create(:first_name => 'test', :last_name => 'test', :school_id => 1)
    @student = @parent.children.build(:first_name => 'test', :last_name => 'jr')
    #@parent.children << @student
    @parent.expects(:get_matches_for).returns(Array.new(n){ Student.new })
  end

  def prep_destroy(n = 1)
    @student = Student.new
    @parents = [@mom = Parent.new, @dad = Parent.new]
    @parents.stubs(:count).returns(n)
    @mom.expects(:children).at_least_once.returns([@student])
    @student.stubs(:parents).returns(@parents)
  end

  def stub_parent(children = [@child = Student.new])
    @parent = Parent.new
    @parent.stubs(:children).returns(children)
  end

end

