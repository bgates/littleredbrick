require 'test_helper'

class GradeUploadTest < ActiveSupport::TestCase

  def test_prepare_grades_no_students
    stub_open('good.xls')
    @upload.stubs(:data).returns([])
    filename = 'fail.xls'
    @upload.prepare_grades(@section, {:filename => filename, :import => {}})
    assert !@upload.valid?
  end

  def test_prepare_grades_empty
    Grade.expects(:where).returns([])
    @upload = GradeUpload.new
    @upload.expects(:data).returns([])
    @upload.expects(:collect_students).returns([Student.new])
    @upload.prepare_grades(@section, {:import => {}})
    @upload.expects(:check_existence_and_filetype).returns(true)
    assert !@upload.valid?
    assert_equal @upload.errors[:base], ["You must choose at least one assignment"]
  end

  def test_prepare_grades
    stub_open('good.xls')
    @upload.expects(:collect_students).returns([1])
    @upload.expects(:setup_grade_hash).returns([@grade = Grade.new])
    #File.expects(:delete).returns(true)
    assert_equal [@grade], @upload.prepare_grades(@section, {:import => {}})
  end

  def test_grade_hash
    @student_1_scores = ['name', 10, 9, 10]
    @student_2_scores = ['name', 0, 0, 0]
    @upload = GradeUpload.new
    @upload.expects(:data).returns([@student_1_scores, @student_2_scores])

    @grades = []
    @students = [1, 2]
    @assignment_list = {'1' => '10', '2' => '11', '3' => '12'}
    @students.each do |s|
      @assignment_list.each do |n, id|
        @grades << grade = stub(:rollbook_entry_id => s, :assignment_id => id.to_i, :id => s * id.to_i)
      end
    end
    Grade.expects(:where).returns(@grades)
    @expected_return = {10 => {'score' => 10}, 11 => {'score' => 9}, 12 => {'score' => 10}, 20 => {'score' => 0}, 22 => {'score' => 0}, 24 => {'score' => 0}}
    assert_equal @expected_return, @upload.setup_grade_hash(@students, @assignment_list)
  end

  def test_update_all
    @upload = GradeUpload.new
    @upload.stubs(:grades).returns({1 => 'score', 3 => 'higher score'})
    Grade.expects(:update).with([1, 3], ['score', 'higher score']).returns([Grade.new, Grade.new])
    assert @upload.update_all
  end

  def test_collect_students
    @upload = GradeUpload.new
    @data = [['LastCOMMA   First', 1, 2, 4], ['SurnameCOMMAForename', 3, 2, 1]]
    @upload.expects(:data).returns(@data)
    @rbes = [stub(:id => 10, :student => stub(:last_first => 'Surname, Forename')), stub(:id => 100, :student => stub(:last_first => 'Last, First'))]
    @section = stub(:rollbook_entries => @rbes)
    assert_equal [100, 10], @upload.collect_students(@section, 'last_first')
  end

  protected

  def stub_open(file)
    @section = Section.new
    File.stubs(:join).returns(File.dirname(__FILE__) + '/../uploads/upload/' + file)
    @upload = GradeUpload.open(file)
  end
end

