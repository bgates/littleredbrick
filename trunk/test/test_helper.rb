require 'cover_me'
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'rails/test_help'
require 'mocha'

include AuthenticatedTestHelper
include ActionDispatch::TestProcess
class ActiveSupport::TestCase
  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  self.use_transactional_fixtures = true
  self.pre_loaded_fixtures = true

  self.use_instantiated_fixtures  = false

  # Add more helper methods to be used by all tests here...
  def assert_same_elements(a1, a2, msg = nil)
    [:select, :inject, :size].each do |m|
      [a1, a2].each {|a| assert_respond_to(a, m, "Are you sure that #{a.inspect} is an array?  It doesn't respond to #{m}.") }
    end

    assert a1h = a1.inject({}) { |h,e| h[e] = a1.select { |i| i == e }.size; h }
    assert a2h = a2.inject({}) { |h,e| h[e] = a2.select { |i| i == e }.size; h }

    assert_equal(a1h, a2h, msg)
  end

  def generic_setup(klass = Staffer)
    @request.session[:school] = @request.session[:user] = :exists
    @controller.stubs(:set_user).returns(@user = klass.new)
    @school = School.new(:low_grade => 1, :high_grade => 10)
    @user.stubs(:school).returns @school
    [Assignment, Department, Forum, Section, Subject, User, Parent, Staffer, Student, Teacher, Term, Track].each do |model|
      model.any_instance.stubs(:to_param).returns model.name
    end
  end

  def stub_role
    Role.stubs(:find_by_title).returns Role.new
  end

  def term_setup
    @term = Term.new
    @school.stub_path('terms.find').returns(@term)
    @term.stubs(:to_param).returns 'term'
  end

  def login_as(user)
    @request.session[:user] = user ? users(user).id : nil
    @request.session[:topics] = {}
  end

  def authorize_as(user, pwd = 'test', mime_type = 'application/xml')
    @request.env["HTTP_AUTHORIZATION"] = user ? ActionController::HttpAuthentication::Basic.encode_credentials(users(user).authorization.login, pwd) : nil
  end

  def logout
    @request.session[:user] = nil
    @controller.instance_variable_set("@current_user",nil)
  end

  def content_type(type)
    @request.env['Content-Type'] = type
  end

  def accept(accept)
    @request.env["HTTP_ACCEPT"] = accept
  end

  def assert_models_equal(expected_models, actual_models, message = nil)
    to_test_param = lambda { |r| "<#{r.class}:#{r.to_param}>" }
    full_message = build_message(message, "<?> expected but was\n<?>.\n",
      expected_models.collect(&to_test_param), actual_models.collect(&to_test_param))
    assert_block(full_message) { expected_models == actual_models }
  end

  def prep_mp
    @mp = stub(:position => 1, :reported_grade_id => 2)
    @controller.expects(:find_from_track).returns([@mp])
    Track.expects(:current_marking_period).returns(@mp)
  end

  fixtures :all
end

module Mocha
  module ObjectMethods
    def stub_path(path)
      path = path.split('.') if path.is_a? String
      raise "Invalid Argument" if path.empty?
      part = path.shift
      mock = Mocha::Mockery.instance.named_mock(part)
      exp = self.stubs(part)
      if path.length > 0
        exp.returns(mock)
        return mock.stub_path(path)
      else
        return exp
      end
    end
  end
end

