require 'test_helper'

class EnrollmentUploadTest < ActiveSupport::TestCase

  def setup
    @upload = EnrollmentUpload.new
  end

  def test_create_enrollments
    @upload.expects(:valid?).returns(true)
    @students = [stub(:full_name => 'One Student'), stub(:full_name => 'Another Student')]
    @rbes = [stub(:student => @students[0], :id => 1000), stub(:student => @students[1], :id => 2000)]
    @section = stub(:rollbook_entries => @rbes)

    @teacher = Teacher.new
    Student.expects(:where).returns(@students)
    @upload.expects(:get_rbes).with(:id_method => 'full_name').returns(@rbes)
    RollbookEntry.expects(:import).with(@rbes, :validate => false)
    RollbookEntry.expects(:bulk_grades_and_milestones_for)
    @upload.create_enrollment(@teacher, :id_method => 'full_name')
  end

  def test_rbes_empty
    @data = [['student class_1', 'student class_2'], ['other_student class_1', 'other_student class_2']]
    @upload.expects(:data).returns(@data)
    @upload.stubs(:sections).returns([Section.new])
    assert_equal [], @upload.get_rbes(:id_method => 'full_name', :section => ['1', '2'])
  end

  def test_rbes
    @data = [['student class_1', 'student class_2'], ['other_student class_1', 'other_student class_2']]
    @upload.expects(:data).returns(@data)
    @upload.stubs(:sections).returns(@sections = Array.new(3){Section.new})
    @sections.each_with_index{|s, i| s.stubs(:id).returns(i)}
    @students = @data.flatten.map{|name| stub(:full_name => name, :id => name.length)}
    @upload.stubs(:students).returns(@students)
    assert_equal 4, @upload.get_rbes(:id_method => 'full_name', :section => %w(0 1 2)).length
  end

  def test_rbes_reversed_names
    @data = [['class_1COMMA student', 'class_2COMMA student'], ['class_1COMMA other_student', 'class_2COMMA other_student']] #damn commas
    @upload.expects(:data).returns(@data)
    @upload.stubs(:sections).returns(@sections = Array.new(3){Section.new})
    @sections.each_with_index{|s, i| s.stubs(:id).returns(i)}
    @students = @data.flatten.map{|name| stub(:last_first => name.sub(/COMMA/, ','), :id => name.length)}
    @upload.stubs(:students).returns(@students)
    assert_equal 4, @upload.get_rbes(:id_method => 'last_first', :section => %w(0 1 2)).length
  end

  def test_validity
    @upload.expects(:rbes).returns([RollbookEntry.new])
    @upload.expects(:check_existence_and_filetype).returns(true)
    assert @upload.valid?
  end

  def test_invalid
    @upload.expects(:rbes).returns([])
    @upload.expects(:check_existence_and_filetype).returns(true)
    assert @upload.invalid?
  end
end

