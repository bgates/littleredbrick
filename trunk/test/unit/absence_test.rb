require 'test_helper'

class AbsenceTest < ActiveSupport::TestCase

  def setup
    @sections = [stub(:time => 0, :id => 1), stub(:time => 2, :id => 2), stub(:time => 5, :id => 3)]
    @today = Date.today
    @absences = []
    1.upto(3){|n| @absences << stub(:date => @today - 30, :code => 1, :section_id => n)}
    1.upto(3){|n| @absences << stub(:date => @today - 1, :code => 0, :section_id => n)}
    1.upto(5){|n| @absences << stub(:date => @today - n, :code => 3, :section_id => n)}
  end

  def test_summary
    day, period = Absence.summary(@sections, @absences)
    assert_equal day, {1 => 1}
    assert_equal period, {0 => 3, 3 => 5}
  end

  def test_parent_notice
    @result = Absence.parent_notice(@absences, @sections)
    assert_equal @result[:excused_days], {1 => 1}
    assert_equal @result[:excused_periods], {}
    assert_equal @result[:unexcused_days], {}
    assert_equal @result[:unexcused_periods], {0 => 3, 3 => 5}
  end

  def test_destroy
    abs = Absence.create(:student_id => 1, :rollbook_entry_id => 1, :section_id => 1, :code => 0, :date => Date.today)
    abs.update_attributes(:code => '')
    assert_nil Absence.find_by_id(abs)
  end
end

