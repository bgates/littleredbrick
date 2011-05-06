require 'test_helper'

class TermTest < Test::Unit::TestCase

  def test_create
    create_term
    assert @term.valid?
    assert_equal 4, @term.reported_grades.size
    assert_equal 2, @term.tracks.size
    @term.tracks.each{|track| assert_equal 4, track.marking_periods.size}
  end

  def test_create_no_tracks
    create_term(:n_tracks => '')
    assert @term.valid?
    assert_equal 1, @term.tracks.size
    assert_equal 4, @term.tracks[0].marking_periods.size
  end

  def test_multitrack
    @term = Term.new
    @term.expects(:tracks).returns(stub(:count => 2))
    assert @term.multitrack?
    @single_track = Term.new
    assert !@single_track.multitrack?
  end

  def test_start
    create_term(:start => 'invalid')
    assert_equal "must be in date format (yyyy-mm-dd)", @term.errors[:start][0]
  end

  def test_finish
    create_term(:finish => 'invalid')
    assert_equal ['must be in date format (yyyy-mm-dd)', 'must be later than the start'], @term.errors[:finish]
    create_term(:finish => Date.today - 30)
    assert_equal 'must be later than the start', @term.errors[:finish][0]
  end

  def test_sorting_reported_grades
    @term = Term.new
    ReportedGrade.expects(:sort)
    @term.reported_grades_with_sort
  end

  def test_period_order
    create_term(:low_period => 2, :high_period => 1)
    assert !@term.valid?
  end

  def test_period_existence
    @term = Term.new(:low_period => 1)
    @term.valid?
    assert !@term.errors[:high_period].empty?
  end

  def test_duration
    start = Date.today
    finish = Date.today - 1
    @term = Term.new(:start => start, :finish => finish)
    @term.valid?
    assert !@term.errors[:finish].empty?
  end
protected

  def create_term(options = {})
    @term = Term.create({:school_id => 1, :n_marking_periods => 4, :n_tracks => 2, :start => Date.today.strftime("%Y-%m-%d"), :finish => (Date.today + 30).strftime("%Y-%m-%d"), :high_period => 5}.merge(options))
  end
end

