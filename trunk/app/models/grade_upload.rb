class GradeUpload < Upload
  attr_accessor :grades
  validate :students_and_assignments
  def prepare_grades(section, params)
    @students = collect_students(section, params[:student])
    @grades = setup_grade_hash(@students, params[:import])
    @grades
  end

  def update_all
    Grade.update(grades.keys, grades.values)
  end

  #the removal of commas is a big goddamn problem.
  def collect_students(section = nil, student_attr = nil)
    @students ||= (
    student_list = data.collect{|row| row[0].to_s.sub(/COMMA\s*/,', ').strip}
    students = student_list.collect do |student|
      s = section.rollbook_entries.detect{|rbe| rbe.student.send(student_attr) == student}
      s && s.id
    end
    students)
  end

  def setup_grade_hash(students, assignment_list)
    assignment_ids = assignment_list.values.reject{|n|n.to_s.empty?}
    grades = Grade.where(['assignment_id IN (?)', assignment_ids])
    grade_hash = {}
    data.each_with_index do |row, i|
      row.each_with_index do |cell, j|
        next if j == 0
        g = grades.detect{|g| g.rollbook_entry_id == students[i] && g.assignment_id == assignment_list[j.to_s].to_i}
        g = g.id unless g.nil?
        grade_hash[g] = {'score' => cell}
      end
    end
    grade_hash.delete_if{|h,k|h.nil?}
  end

  protected

  def students_and_assignments
    must_have_students
    must_have_assignments
  end

  def must_have_assignments
    errors.add(:base, "You must choose at least one assignment") if grades.empty?
  end

  def must_have_students
    if @students && @students.compact.empty?
      errors.add(:base, "No students from this class could be identified based on the information you entered. You may have selected the wrong option to identify the data in the first column.")
    end
  end
end

