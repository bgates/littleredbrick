require 'test_helper'

class SchoolTest < ActiveSupport::TestCase

  def setup
    @school = School.new
  end

  def test_import
    @orphan1 = stub(:login => 'jondoe', :id => 1, :parents => [], :full_name => 'Jon Doe')
    @orphan2 = stub(:login => 'janedoe', :id => 2, :parents => [], :full_name => 'Jane Doe')
    @has_parents = stub(:login => 'x', :id => 404, :parents => [:parent])
    @school.expects(:students).returns(stub(:includes => [@orphan1, @orphan2, @has_parents]))

    @parents = [stub(:id => 10, :login => 'jondoe_father', :children => []), stub(:id => 20, :login => 'janedoe_father', :children => []), stub(:id => 100, :login => 'jondoe_mother', :children => []), stub(:id => 200, :login => 'janedoe_mother', :children => []), stub(:children => [:child])]
    @school.expects(:initialize_parents_from).with([@orphan2, @orphan1])
    @school.expects(:parent_import)
    @school.expects(:parents).returns(stub(:includes => @parents))
    ActiveRecord::Base.connection.expects(:insert).with("INSERT INTO parents_students (parent_id, student_id) VALUES (20, 2),(200, 2),(10, 1),(100, 1)")
    @school.add_parents_bulk
  end

  def test_parent_import
    @parents = [Parent.new(:first_name => 'ma', :last_name => 'parent'), Parent.new(:first_name => 'pa', :last_name => 'parent')]
    @parents.each{|p|p.build_authorization(:login => p.first_name + p.last_name)}
    User.expects(:import).with(@parents, :validate => false)
    Parent.expects(:find_all_by_school_id).returns(@parents)
    Authorization.expects(:import).with(@parents.map(&:authorization), :validate => false)
    @school.parent_import(@parents)
  end

  def test_initial_teacher
    user = @school.initial_user(:teacher => 'yes', :user => {:first_name => 'Teacher'})
    assert_equal(user.class, Teacher)
  end

  def test_initial_teacher_individual
    user = @school.initial_user(:user => { :first_name => 'Teacher' })
    assert_equal(user.class, Teacher)
  end

  def test_initial_staffer
    user = @school.initial_user(:group => true, :user => { :first_name => 'Staffer' })
    assert_equal(user.class, Staffer)
  end

  def test_initialize_parents
    children = [Authorization.new(:school_id => 1, :login => 'test'), Authorization.new(:school_id => 1, :login => 'testa')]
    @parents = @school.initialize_parents_from(children)
    assert_equal 4, @parents.length
    assert_equal 'testa_mother', @parents.last.authorization.login
    @parents.each{|p|assert p.valid?}
  end

  def test_create
    @school = School.new(:name => 'test', :domain_name => 'test', :low_grade => 9, :high_grade => 12, :teacher_limit => 10)
    @teacher = Teacher.new(:first_name => 'test', :last_name => 'contact')
    @school.contact = @teacher

    UserNotifier.expects(:welcome_email).with(@school, @teacher).returns(stub :deliver => true)
    UserNotifier.expects(:school_creation_notification).with(@school, @teacher).returns(stub :deliver => true)
    @teacher.stubs(:make_admin).returns @teacher
    assert @school.save
  end
end

