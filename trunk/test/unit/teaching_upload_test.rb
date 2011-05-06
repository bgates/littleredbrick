require 'test_helper'

class TeachingUploadTest < Test::Unit::TestCase

  def setup
    @upload = TeachingUpload.new
  end

  def test_teachers_subjects
    @teacher_1_classes = ['Don Wilhour', 'Calculus', 'Trig', 'Calculus']
    @teacher_2_classes = ['Russ Palkendo', 'AP History', 'Psych', 'Civics']
    @unknown_teacher = ['Name not found', 'Math', 'Science', 'Other']
    @upload.stubs(:data).returns([@teacher_1_classes, @teacher_2_classes, @unknown_teacher])

    @teachers = [stub(:full_name => 'Don Wilhour', :id => 314), stub(:full_name => 'Russ Palkendo', :id => 1942)]
    @subjects = [stub(:name => 'Calculus', :id => 101), stub(:name => 'Trig', :id => 102), stub(:name => 'AP History', :id => 201), stub(:name => 'Psych', :id => 202), stub(:name => 'Civics', :id => 203)]
    @term = stub(:low_period => 1, :tracks => [stub(:id => 1)])

    @school = stub(:teachers => @teachers, :terms => stub(:order => stub(:includes => stub(:first => @term))), :departments => stub(:select => ''))
    Subject.expects(:where).returns(@subjects)
    @upload.match_teachers_and_subjects('true', @school)
    sections = @upload.sections

    assert_equal sections.map(&:teacher_id), [314, 314, 314, 1942, 1942, 1942]
    assert_equal sections.map(&:subject_id), [101, 102, 101, 201, 202, 203]
    assert sections.all?(&:current)
    assert_equal [1], sections.map(&:track_id).uniq
  end

  def test_validity
    @upload.expects(:sections).returns([Section.new])
    @upload.expects(:check_existence_and_filetype).returns(true)
    assert @upload.valid?
  end

  def test_invalid
    @upload.expects(:sections).returns([])
    @upload.expects(:check_existence_and_filetype).returns(true)
    assert @upload.invalid?
  end

  def test_create
    @upload.expects(:match_teachers_and_subjects).returns(true)
    @upload.stubs(:sections).returns([[]])
    Section.expects(:import).returns(mock)
    assert_equal 1, @upload.create_sections('true', :school)
  end
end

