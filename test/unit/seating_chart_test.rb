require 'test_helper'

class SeatingChartTest < ActiveSupport::TestCase

  def test_validate_no_missing
    @seats = {0 => {0 => '1', 1 => '2'}, 1 => {0 => '3'}}
    @chart = SeatingChart.new(@section = Section.new, @seats)
    @section.expects(:enrollment).returns(4)
    assert !@chart.valid?
  end

  def test_validate_no_repeats
    @students = Array.new(3){RollbookEntry.new}
    @seats = {0 => {0 => '1', 1 => '2'}, 1 => {0 => '2'}}
    @chart = SeatingChart.new(@section = Section.new, @seats)
    @section.expects(:rollbook_entries).returns(@students)
    @section.expects(:enrollment).returns(3)
    assert !@chart.valid?
  end

  def test_valid
    stub_setup
    assert @chart.valid?
  end

  def test_save
    @students = Array.new(3){RollbookEntry.new}
    @students.each_with_index{|s, n| s.stubs(:id).returns(n + 1);s.expects(:save)}
    stub_setup
    @section.stubs(:rollbook_entries).returns(@students)
    @chart.save
    assert_equal [1, 0], [@students.last.x, @students.last.y]
  end

  def stub_setup
    @seats = {0 => {0 => '1', 1 => '2'}, 1 => {0 => '3'}}
    @chart = SeatingChart.new(@section = Section.new, @seats)
    @section.expects(:enrollment).returns(3)
  end
end

