class Assignment < ActiveRecord::Base
  belongs_to                    :section
  belongs_to                    :reported_grade
  has_many                      :grades, :dependent => :destroy
  has_many                      :rollbook_entries, :through => :grades
  #after_initialize              :set_dates
  before_validation             :set_date_assigned
  after_validation              :cleanup_errors,
                                :if => :has_individual_due_dates? 
  after_validation              :remove_individual_due_dates,
                                :unless => :has_individual_due_dates_or_new?
  validates_presence_of         :date_assigned, :category
  validates_presence_of         :date_due,
                                :unless => :has_individual_due_dates?
  validates_associated          :grades, :if => :has_individual_due_dates?,
                                :message => 'are invalid. Make sure each student has been given a due date, and all due dates are on or after the date the assignment was given.'
  validates_numericality_of     :point_value
  validate                      :check_due_date
  before_save                   :edit_marking_periods, :unless => :new_record?
  before_save                   :set_name, :delete_attachment
  after_create                  :initialize_grades,
                                :unless => :has_individual_due_dates?
  after_save                    :scale_grades, :if => :scale
  attr_accessor                 :individual_due_dates, :scale, 
                                :remove_attachment
  acts_as_list                  :scope => :section_id
  has_attached_file             :attachment

  delegate :teacher, :to => :section

  def self.categories
    select('DISTINCT assignments.category').map(&:category)
  end

  def self.category_points(category, mp)
    where(["category = ? AND reported_grade_id = ?", category, mp]).sum('point_value')
  end

  def self.marking_period_points(mp)
    where(["reported_grade_id = ?", mp]).sum('point_value')
  end

  def self.near(assignment)
    positions = (assignment.position - 2..assignment.position + 2)
    where(['position IN (?)', positions]).order(:position)
  end

  def attachment_extension
    File.extname(attachment_file_name).downcase.sub(/^\./,'')
  end

  def audience; section.name; end

  def average_pct(_grades = nil)
    begin
      (average_score(_grades) / point_value.to_f) * 100
    rescue
    'N/A'
    end
  end

  def average_score(_grades = grades)
    return @score if @score
    graded = _grades.reject{|g| !g.graded?}
    @score = graded.empty?? nil : graded.sum(0){|g| g.score.to_f } / graded.length.to_f
  end

  def date; date_due; end

  def default_grade_for(rollbook_entry)
    grades.create(:rollbook_entry_id => rollbook_entry.id)
  end

  def due_recently?
    date_due && date_due > Date.today - 7 && date_due <= Date.today
  end

  def due_soon?
    date_due && date_due > Date.today
  end

  def editable_by?(user)
    section.teacher_id == user.id
  end
  
  def self.for_sections(start, finish, sections)
    where(["(date_due BETWEEN ? AND ?) AND section_id IN (?)", start, finish, sections]).order('date_due')
  end

  def graded?
    grades.select{|g| g.graded?}.length >= 0.5 * grades.length
  end

  def grades=(grade_hash)
    self.date_due = nil
    @individual_due_dates = true
    grade_hash.each do |grade_id, attributes|
      attributes.merge!(:date_assigned => date_assigned, :check_date => true)
      grades.detect{|g|g.id.to_s == grade_id}.update_attributes(attributes)
    end
  end

  def initialize_grades
    section.rollbook_entries.each{|rbe| default_grade_for(rbe)}
  end

  def marking_period_number
    reported_grade.description.gsub(/[^0-9]/,'')
  end

  def name; title; end

  def new_grades=(new_grades)
    @individual_due_dates = true
    new_grades.each do |rbe, hash|
      grades.build(hash.merge(:rollbook_entry_id => rbe, :date_assigned => date_assigned, :check_date => true))
    end
  end

  def point_value
    super.to_i
  end

  def scalable?
    !new_record? && point_value != 0 
  end

  protected
 
  def check_due_date
    if date_due && date_assigned > date_due
      errors.add(:date_assigned, 'must be on or before due date')
    end
  end

  def cleanup_errors
    if errors[:date_due] && grades.any?{|g| g.errors[:date_due].empty?}
      errors.delete(:date_due)
      errors[:grades].uniq!
      errors[:grades].delete_if{|string| string == 'is invalid'}
    end
  end

  def edit_marking_periods
    if point_value_changed? || reported_grade_id_changed?
      grades.each do |grade|
        grade.assignment_changes_marking_period(self)
      end
    end
  end
 
  def has_individual_due_dates?
    individual_due_dates
  end

  def has_individual_due_dates_or_new?
    individual_due_dates || new_record?
  end

  def remove_individual_due_dates
    grades.each{|g| g.update_attribute(:date_due, nil)}
  end

  def delete_attachment
    self.attachment = nil if remove_attachment
  end

  def scale_grades
    scale_factor = point_value.to_f / point_value_was
    grades.reject{|g| !g.graded?}.each do |grade|
      grade.scale(scale_factor)
    end
  end

  def set_dates
    if new_record?
      self.date_assigned ||= Date.today
      self.date_due ||= Date.today + 1
    end
  end

  def set_date_assigned
    self.date_assigned ||= Date.today
  end

  def set_name
    self.title = "Assignment #{position}" if title.blank?
  end
end
