require 'test_helper'

class UserTest < ActiveSupport::TestCase

  def test_valid_user
    new_user.add_default_attributes
    assert new_user.valid?
    assert_equal @user.authorization.login, 'quirequire'
  end

  def test_authorization
    new_user.save
    assert auth = Authorization.find_by_user_id(@user)
    assert_equal auth.login, @user.first_name + @user.last_name
    assert_equal @user, Authorization.authenticate(auth.login, auth.login, auth.school_id)
  end

  def test_authorization_reset
    new_user.save
    @user.update_attributes(:first_name => 're', :last_name => 'set', :reauthorize => '1')
    @refresh = User.find(@user)
    assert_equal 'reset', @refresh.login
    assert Authorization.find_by_login('reset')
  end

  def test_other_authorization_reset
    new_user.save
    @old_login = @user.login
    @user.update_attributes(:first_name => 'chan', :last_name => 'ged')
    @refresh = User.find(@user)
    assert_equal @old_login, @refresh.login
    @refresh.update_attributes(:reauthorize => '1')
    @final = User.find_by_first_name('chan')
    assert_equal 'changed', @final.login
  end

  def test_default_user
    @user = User.default(:first_name => ' bob ', :last_name => 'spaceless')
    assert_equal 'bobspaceless', @user.login
  end

  [:first_name, :last_name].each do |name|
    test_name = "test_should_require_#{name.to_s}"
    define_method(test_name) do
      new_user(name => nil).save
      assert !@user.errors[name].empty?
    end
  end

  def test_should_reset_password
    new_user.save
    @user.authorization.update_attributes(:password => 'new password', :password_confirmation => 'new password')
    assert auth = Authorization.find_by_user_id(@user)
    assert_equal 'quirequire', auth.login
    assert_equal 1, auth.school_id
    assert_equal @user, Authorization.authenticate(auth.login, 'new password', auth.school_id)
    #assert_equal @user, Authorization.authenticate('quirequire', 'new password', 1)
  end

  def test_should_not_rehash_password
    new_user.save
    @user.authorization.update_attributes(:login => 'quentin2')
    assert_equal @user, Authorization.authenticate('quentin2', 'quirequire', 1)
  end

  def test_should_authenticate_user
    new_user.save
    assert_equal @user, Authorization.authenticate('quirequire', 'quirequire', 1)
  end

  def test_should_create_student
    @student = Student.new({ :first_name => 'Paul', :last_name => 'Davies', :school_id => 1 })
    assert @student.valid?
  end

  def test_no_duplicate_id_numbers
    2.times {|i| new_user({:id_number => '123456'}).save}
    assert !@user.errors[:id_number].empty?
  end

  def test_allow_duplicate_id_number_and_login_at_different_schools
    @students = []
    2.times{|n| new_user(:id_number => '123456', :school_id => n).save!;@students << @user}
    assert @students.all?{|s| s.valid?}
    assert @students[0].authorization.login == @students[1].authorization.login
  end

  def test_whitespace_removal
    user = new_user({:first_name => '  John  ', :last_name => ' Wayne   '})
    user.valid?
    assert_equal user.first_name, 'John'
    assert_equal user.last_name, 'Wayne'
  end

  def test_name_reversal_and_fullname
    user = new_user
    user.last_first = 'Bond, James'
    assert_equal user.full_name, 'James Bond'
    user.full_name = 'Sean Connery'
    assert_equal user.last_name, 'Connery'
  end

  def test_recent_posts
    @discussable = Section.new
    @user = User.new
    @post = Post.new
    @user.posts.stub_path('where.limit.select.joins.order').returns([@post]) ## wanted to include 'with' clause, but it has a call to Time.now which is different between setting the expectation and making the actual call in recent_posts
    assert_equal @user.recent_posts(@discussable, {}), [@post]
  end

  def test_owns_forum
    @forum = Forum.new(:owner_id => 1)
    @user = User.new
    @user.expects(:id).returns(1)
    assert @user.owns?(@forum)
  end

  def test_events
    @user = User.new
    start, finish = Date.today, Date.today + 7
    @user.expects(:id).returns('id')
    @user.expects(:school_id).returns('school')
    MarkingPeriod.expects(:on_calendar).with('track', start, finish).returns([])
    Event.expects(:where).with(["invitable_type = 'User' AND invitable_id = ? AND date BETWEEN ? AND ?", 'id', start, finish]).returns([])
    Event.expects(:where).with(["invitable_type = 'School' AND invitable_id = ? AND date BETWEEN ? AND ?", 'school', start, finish]).returns([])
    assert_equal [], @user.universal_events(start, finish, 'track')
  end

  def test_import_with_auth
    User.expects(:import)
    user = User.new(:first_name => 'First', :last_name => 'Last', :school_id => 1)
    User.stub_path('where.includes.select').returns [user]
    Authorization.expects(:import)
    User.import_with_authorizations([user])
  end

  def test_search
    User.expects(:where).with(['(LOWER(last_name) LIKE :q OR LOWER(first_name) LIKE :q) AND school_id = :s', {:q => "%name%", :s => 1}]).returns 'result'
    assert_equal('result', User.search('NAME', :school_id => 1))
    
  end
  def test_build_authorization
    @user = User.new(:school_id => 1)
    @user.authorization = {:login => 'test'}
    assert_equal 'test', @user.authorization.login
  end

  def test_quick_valid
    user = User.new
    user.build_authorization(:login => 'exists')
    assert !user.quick_valid?('exists')
    [:first_name, :last_name, :login].each do |attr|
      assert user.errors[attr]
    end
  end
  protected
  def new_user(options = {})
    @user = User.new({ :first_name => 'quire', :email => 'quire@example.com', :last_name => 'quire' , :id_number => '4313', :school_id => 1}.merge(options))
  end
end

