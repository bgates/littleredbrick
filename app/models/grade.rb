class Grade < ActiveRecord::Base
  DEFAULT_SCORE = '-'
  belongs_to               :rollbook_entry
  belongs_to               :assignment
  belongs_to               :section
  validates_format_of      :score, :with => /^(\d+\.{0,1}\d*)$|#{DEFAULT_SCORE}/
  validates_presence_of    :date_due, :unless => :no_need_or_other_validation_collides
  validate                 :check_due_date
  before_validation        :set_default_score, :on => :create
  before_update            :edit_marking_period, :if => :score_changed?
  before_destroy           :remove_from_marking_period
  attr_accessor            :date_assigned, :check_date
  delegate :audience, :description, :section, :point_value, :to => :assignment

  def self.for_sections(start, finish, sections)
    where(["assignments.date_due IS ? AND (grades.date_due BETWEEN ? AND ?) AND assignments.section_id IN (?)", nil, start, finish, sections]).includes([:assignment, {:rollbook_entry => :student}]).order('grades.date_due')
  end

  def self.ungraded(rbes)
    where(['rollbook_entry_id IN (:rbe) AND ((assignments.date_due BETWEEN :start AND :finish) OR (grades.date_due BETWEEN :start AND :finish))', 
    { :rbe => rbes.map(&:id), :start => Date.today, :finish => Date.today + 7 }]).includes({:assignment => {:section => :subject}}).sort_by{|g|g.due}
  end

  def assignment_changes_marking_period(_assignment)
    change_marking_period(:-, _assignment.point_value_was, 
                              _assignment.reported_grade_id_was)
    change_marking_period(:+, _assignment.point_value, 
                              _assignment.reported_grade_id)
  end

  def change_marking_period(sign, points, reported_grade_id)
    if graded?
      find_marking_period(reported_grade_id)
      @marking_period.change(sign, score, points)
    end
  end

  def due
    assignment.date_due || date_due
  end

  def date; due; end

  def editable_by?(user); assignment.editable_by?(user); end

  def edit_marking_period
    find_marking_period(assignment.reported_grade_id)    
    @marking_period.change_points_maybe_possible(score, score_was, assignment)
  end

  def find_marking_period(mark)
    @marking_period = Milestone.find_by_rollbook_entry_id_and_reported_grade_id(rollbook_entry_id, mark)
  end

  def graded?
    score.to_f.to_s == score.to_s || score.to_i.to_s == score.to_s
  end

  def percent(_assignment = nil)
    if graded?
      score.to_f / (_assignment || assignment).point_value.to_f * 100
    end
  end

  def remove_from_marking_period
    change_marking_period('-', point_value,
                               assignment.reported_grade_id)
  end

  def scale(scale_factor)
    new score= ("%01.1f" % ((score.to_f * scale_factor * 10).round.to_f / 10)).to_f
    new_score = new_score.to_i if score.is_a?(Integer) && new_score.to_i == new_score
    update_attributes(:score => new_score)
  end

  private

  def check_due_date
    unless no_need_to_check_due_date || good_due_date
      errors.add(:date_due, 'for each grade must be on or after the date the assignment was assigned')
    end
  end

  def good_due_date
    date_due && date_assigned && date_due >= date_assigned
  end

  def no_need_or_other_validation_collides
    no_need_to_check_due_date || !good_due_date
  end

  def no_need_to_check_due_date
    !check_date
  end

  def set_default_score
    self.score = DEFAULT_SCORE
  end
end

