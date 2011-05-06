class Milestone < ActiveRecord::Base
  belongs_to                   :rollbook_entry
  belongs_to                   :reported_grade
  validates_numericality_of    :earned, :possible

  def average_of(predecessors)
    weight_by(predecessors, Hash.new(100.0 / predecessors.length))
  end

  def calculate
    (earned / possible) * 100.0
  end

  def change(sign, score, points)
    self.earned = self.earned.send(sign, score.to_f)      
    self.possible = self.possible.send(sign, points)
    save
  end

  def change_points_maybe_possible(current, previous, assignment)
    self.earned += (current.to_f - previous.to_f)
    if previous == '-'
      self.possible += assignment.point_value
    elsif current == '-'
      self.possible -= assignment.point_value
    end
    save
  end

  def class_milestones
    query = "SELECT * from milestones WHERE reported_grade_id =#{reported_grade_id}" +
    " AND rollbook_entry_id IN (SELECT id from rollbook_entries " +
    "WHERE section_id = (SELECT section_id from rollbook_entries " +
    "WHERE id = #{rollbook_entry_id}))"
    Milestone.find_by_sql(query)
  end

  def class_rank
    class_milestones.sort_by{|m| m.grade.to_f}.reverse.index(self) + 1
  end

  def combine(predecessors)
    self.earned, self.possible = predecessors.sum(&:earned), predecessors.sum(&:possible)
    save
  end

  def grade
    possible > 0 ? (earned / possible) * 100.0 : '-'
  end

  def reset!
    grades = rollbook_entry.grades.where(["assignments.reported_grade_id = ?", reported_grade_id]).includes(:assignment).select(&:graded?)
    self.earned = grades.sum{|g| g.score.to_i}
    self.possible = grades.sum{|g| g.point_value.to_f}
    save!
  end

  def weight_by(predecessors, weights) #weights are all integers (ie 40, 40, 20 not 0.4, 0.4, 0.2)
    if predecessors.any?{|p| p.possible == 0}
      errors.add(:base, 'cannot calculate average based on ungraded mark')
    else
      self.earned = predecessors.sum{|p| weights[p.reported_grade_id.to_s].to_f * p.earned / p.possible}
      self.possible = 100
      save
    end
  end
  
  def self.order(milestones)
    sorted = ReportedGrade.sort(milestones.map(&:reported_grade))
    milestones.sort_by{|m| sorted.index(m.reported_grade)}
  end

  def self.setup(section,rbe)
    required_milestones = section.reported_grades + section.term.reported_grades
    required_milestones.each do |r_grade|
      rbe.milestones.create(:earned => 0, :possible => 0, :reported_grade_id => r_grade.id)
    end
  end
end

