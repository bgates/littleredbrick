class TeachingUpload < Upload
  validate :presence_of_sections
  attr_accessor :sections
  
  def create_sections(current, school)
    match_teachers_and_subjects(current, school)
    return 0 if sections.empty?
    Section.import(sections, :validate => false)
    sections.length
  end
  
  def match_teachers_and_subjects(current, school)
    @subjects = Subject.where(['department_id IN (?)', school.departments.select('departments.id')])
    @teachers, @term = school.teachers, school.terms.order('terms.id DESC').includes(:tracks).first
    @sections = []
    name = first_column_method
    data.each do |row|
      teacher = @teachers.detect{|t| t.send(name) == row[0]}
      next unless teacher
      row.each_with_index do |cell, i|
        next if i == 0 || row[i].nil?
        subject = @subjects.detect{|s| s.name == row[i].to_s.strip}
        next if subject.nil?
        time = @term.low_period == 0 ? i - 1 : i
        @sections << Section.new(:teacher_id => teacher.id, :subject_id => subject.id, :time => time, :track_id => @term.tracks.first.id, :current => current)
      end
    end
  end

  protected
  def presence_of_sections
    errors.add(:base, "It was impossible to identify either names or sections in that file. Make sure you have names or ID numbers of teachers <strong>for whom accounts have been created</strong> in the first column of each row, and the names of subjects in all other columns <strong>exactly</strong> as they appear in your course catalog.") if sections.empty?
  end

  def first_column_method
    [:full_name, :last_first, :last_name, :id_number].each do |name|
      data.each do |row|
        return name if @teachers.detect{|t| t.send(name) == row[0]}
      end
    end
    :id
  end
end
