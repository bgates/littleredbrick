require 'test_helper'
require 'helper_test_helper'

class Term::StagingHelperTest < ActionView::TestCase

  def setup
    self.stubs(:controller).returns @controller = TestController.new
    self.stubs(:current_user).returns @test_user = Teacher.new
  end

  def test_active
    assert !active?('admin')
    params[:subject] = true
    assert active?('admin')
    assert !active?('teacher')
    params[:teacher] = true
    assert active?('teacher')
  end

  def test_no_sections_msg_student
    @student = @test_user
    assert no_sections_msg =~ /You have/
  end

  def test_no_sections_msg_nonstudent
    @student = Student.new(:first_name => 'Name')
    @test_user.expects(:admin?).returns true
    assert no_sections_msg =~ /find a/
  end

  def test_no_sections_msg_teacher
    @teacher = @test_user
    @teacher.expects(:to_param).returns 'id'
    assert no_sections_msg =~ /Your sections/
  end

  def test_no_sections_msg_nonteacher
    @teacher = Teacher.new(:title => 'Mr', :last_name => 'Gates')
    @teacher.expects(:to_param).returns 'id'
    assert no_sections_msg =~ /Mr Gates has/
  end

  protected

    def params
      @params ||= {}
    end
end

