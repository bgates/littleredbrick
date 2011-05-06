class Department < ActiveRecord::Base
  belongs_to              :school
  has_many                :subjects, :dependent => :destroy, :order => 'subjects.name'
  accepts_nested_attributes_for :subjects, :reject_if => :all_blank

  validates_presence_of   :name
  validates_uniqueness_of :name, :scope => :school_id
  validates_associated    :subjects
  validate                :has_subjects, :on => :create
  after_update            :save_subjects
  #TODO: better default catalog (classes, depts) - instead of English 9 etc, have subj generated dynamically by the grades in the school - English 6 7 8, Math 6 7 8, etc
  MATH = %w(Advanced\ Math Algebra\ I Algebra\ II Algebra\ A Algebra\ B Basic\ Math Geometry Calculus Pre-Algebra Statistics Trigonometry)
  SCIENCE = %w(General\ Science Biology\ I Biology\ II Chemistry\ I Chemistry\ II Earth\ Science)
  ENGLISH = %w(English\ 9 English\ 10 Communication Poetry Drama Journalism AP Short\ Story American\ Literature World\ Literature)
  SOCIAL_STUDIES = %w(Social\ Studies Civics Sociology Psychology American\ History World\ History Economics)
  GYM = %w(Physical\ Education Team\ Sports PE\ 9 PE\ 10 PE\ 11 PE\ 12)
  LANGUAGES = %w(Spanish\ I Spanish\ II Spanish\ III Spanish\ IV French\ I French\ II French\ III French\ IV German\ I German\ II German\ III German\ IV)
  CATALOG = {'Mathematics' => MATH, 'English' => ENGLISH, 'Science' => SCIENCE, 'Social Studies' => SOCIAL_STUDIES, 'Physical Education' => GYM, 'Foreign Languages' => LANGUAGES}
  ELEMENTARY = %w(Reading Spelling Math English Science Gym Art Social\ Studies Music)

  def self.generic_choices(level = nil)
    choices = []
    case level
    when 'elementary'
      new_department = Department.new(:name => 'Elementary')
      ELEMENTARY.each{|s| new_department.subjects.build(:name => s)}
      choices << new_department
    else
      CATALOG.each do |dept, subjects|
        new_department = Department.new(:name => dept)
        subjects.each{|s| new_department.subjects.build(:name => s)}
        choices << new_department
      end
    end
    choices
  end

  def self.dummy
    dept = new(:name => 'New department')
    5.times{|n| dept.subjects.build(:name => '')}
    dept
  end

  def self.with_teachers
    includes({ :subjects => {:sections => :teacher} })
  end

  def sections
    Section.where(["subject_id IN (?)", subjects.collect{|s|s.id}])
  end

  def teachers
    section_ids = sections.collect(&:teacher_id)
    return [] if section_ids == []
    Teacher.where(["id IN (?)", section_ids])
  end

  def enrollment(current = true)
    subjects.to_a.sum{|sub| sub.sections.select{|sec| sec.current == current}.sum(&:enrollment)}
  end

  private
    def save_subjects
      subjects.each{|sub| sub.save(:validate => false)}
    end

    def has_subjects
      errors.add(:base, 'A department must have at least one subject') if subjects.empty?
    end
end

