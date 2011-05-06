class ReportedGrade < ActiveRecord::Base
  belongs_to                       :reportable, :polymorphic => true
  validates_presence_of            :description
  attr_accessor                    :allowed
  validates_format_of              :description, :without => /arking/,
                                   :message => "must not be 'marking period'",
                                   :unless => Proc.new{|g| g.allowed}
  validates_uniqueness_of          :description,
                                   :scope => [:reportable_type, :reportable_id],
                                   :unless => Proc.new{|g| g.allowed}
  validate                         :check_name
  before_create                    :set_predecessor, :enumerate
  after_create                     :add_milestones, :insert_predecessor
  before_destroy                   :change_assignment_mp
  after_destroy                    :remove_predecessor
  has_many                         :marking_periods, :dependent => :delete_all
  has_many                         :milestones, :dependent => :delete_all
  has_many                         :assignments#, :dependent => :destroy

  def average_of(predecessors, section)
    predecessor_milestones = gather(predecessors, section)
    gathered_values(section).map do |m| 
      m.average_of(predecessor_milestones[m.rollbook_entry_id])
    end
  end

  def check_name
    return if description =~ /arking/
    if reportable_type == 'Section'
      term = Section.find(reportable_id).term.id
      if (existing_term_grade(description, term) || matching_section_grade(description, reportable_id, id))
        errors.add(:description, 'must be unique')
      end
    end
  end

  def combine(predecessors, section)
    predecessor_milestones = gather(predecessors, section)
    gathered_values(section).map do |m| 
      m.combine(predecessor_milestones[m.rollbook_entry_id])
    end
  end

  def existing_term_grade(description, term)
    ReportedGrade.where(['description = ? AND reportable_id = ? AND reportable_type = ?', description, term, 'Term']).first
  end

  def gather(marks, section)
    section.milestones.where(["reported_grade_id IN (?)", marks]).group_by(&:rollbook_entry_id)
  end

  def gathered_values(section)
    gather(self.id, section).values.flatten
  end

  def matching_section_grade(description, reportable_id, id)
    if new_record?
      ReportedGrade.where(['description = ? AND reportable_id = ? AND reportable_type = ?', description, reportable_id, 'Section']).first
    else
      ReportedGrade.where(['description = ? AND reportable_id = ? AND reportable_type = ? AND id <> ?', description, reportable_id, 'Section', id]).first
    end
  end

  def reset!(section)
    gathered_values(section).map{|m| m.reset!}
  end

  def weight_by(weights, section)
    predecessor_milestones = gather(weights.keys, section)
    gathered_values(section).map do |m| 
      m.weight_by(predecessor_milestones[m.rollbook_entry_id], weights)
    end
  end
  
  def to_s; id; end

  def self.sort(marks)
    return [] if marks.empty?
    @unsorted_term, @unsorted_section = partition_by_type(marks)
    @sorted = [first_element] 
    total_length = (@unsorted_term + @unsorted_section).length
    until @sorted.length >= total_length
      add_milestone_from_section
      add_milestone_from_term
    end
    @sorted.flatten
  end

  protected

    def add_milestones
      case reportable_type
      when 'Term'
        t = Term.find(reportable_id)
        t.sections.each{|s| s.add_milestones(id)}
        if description =~ /Marking Period/
          t.tracks.each{|tr|tr.marking_periods.create(:start => tr.finish + 1, :finish => tr.finish + 30, :reported_grade_id => id)}
        end
      when 'Section'
        Section.find(reportable_id).add_milestones(id)
      end
    end
    
    def change_assignment_mp
      if description =~ /Marking Period/
        t = Term.find(reportable_id)
        previous_mp = t.reported_grades.where(['description LIKE (?) AND id < ?', '%arking%', id]).order('id DESC').first
        return true if previous_mp.nil?
        assignments.each do |assignment|
          assignment.update_attributes(:reported_grade_id => previous_mp.id)
        end
      else
        true
      end
    end

    def enumerate
      if description =~ /Marking Period/
        mps = Term.find(reportable_id).marking_periods.size
        self.description += " #{mps + 1}"
      end
    end

    def insert_predecessor
      rg = reportable_type.constantize.find(reportable_id).reported_grades
      if g = rg.detect{|g| g.predecessor_id == predecessor_id  && g.id != id }
        g.update_attribute(:predecessor_id, id)
      end
    end

    def remove_predecessor
      rg = ReportedGrade.find_all_by_predecessor_id(id)
      rg.each{|g|g.update_attribute(:predecessor_id, predecessor_id)}
    end

    def set_predecessor
      return if self.predecessor_id
      case reportable_type
        when 'Term'
          @rg = Term.find(reportable_id).reported_grades
        when 'Section'
          @rg = Section.find(reportable_id).term.reported_grades
      end
      if @rg.empty?
        self.predecessor_id = 0
      else
        predecessor_list = @rg.collect(&:predecessor_id)
        predecessor = @rg.detect{|g| predecessor_list.include?(g.id) == false}
        self.predecessor_id = predecessor.id
      end
    end

    def self.add_milestone_from_section
      while @unsorted_section.any?{|elm| elm.predecessor_id == @sorted.last.id}
        this, @unsorted_section = @unsorted_section.partition{|elm| elm.predecessor_id == @sorted.last.id}
        @sorted << this[0]
      end
    end

    def self.add_milestone_from_term
      if @unsorted_term.any?{|elm| @sorted.map(&:id).include?(elm.predecessor_id)}
        this, @unsorted_term = @unsorted_term.partition{|elm| @sorted.map(&:id).include?(elm.predecessor_id)}
        @sorted << this[0]
      end
    end

    def self.first_element
      @unsorted_section.detect{|elm| elm.predecessor_id == 0} ||
      @unsorted_term.detect{|elm| elm.predecessor_id == 0}
    end

    def self.partition_by_type(marks)
      marks.partition{|rpg| rpg.reportable_type == 'Term'}
    end
end

