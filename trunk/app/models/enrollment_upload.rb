class EnrollmentUpload < Upload
  attr_accessor :students, :sections, :rbes
  validate      :rollbook_entries_present

  def create_enrollment(teacher, params)
    current = params[:term].blank?
    @students = Student.where(['school_id = ?', teacher.school_id])
    @sections = teacher.sections.where(['current = ?', current]).includes([:assignments, :reported_grades, :rollbook_entries])
    @rbes = get_rbes(params)
    if valid?
      enrollment = 0
      RollbookEntry.import @rbes, :validate => false
      RollbookEntry.bulk_grades_and_milestones_for(@sections)
      @sections.each do |s|
        new_enrollees = -s.rollbook_entries.length + 
                         s.rollbook_entries(true).count 
        enrollment += new_enrollees
        Section.update_counters(s.id, :enrollment => new_enrollees)
      end
      enrollment
    end
  end

  def get_rbes(params)
    rbes = []
    prepped_data = prep_for_transpose(data)
    prepped_data.transpose.each_with_index do |row, i|
      section = sections.detect{|s| s.id == params[:section][i].to_i}
      next unless section
      rollbook_entries = section.rollbook_entries
      position, delta = (rollbook_entries.map{|r|r.position}.max || 0), 0
      row.each do |cell|
        next if cell.blank?
        student = students.detect{|s| s.send(params[:id_method].to_sym) == cell.sub(/COMMA/,',')}
        next if student.nil? || rollbook_entries.any?{|rbe| rbe.student_id == student.id}
        delta += 1
        rbes << RollbookEntry.new(:section_id => section.id, :student_id => student.id, :position => position + delta)
      end
    end
    rbes
  end

  def rollbook_entries_present
    errors.add(:base, 'No students were detected in that file who aren&#39;t already enrolled in these classes.') if rbes.empty?
  end

  def prep_for_transpose(data)
    max = data.max{|a, b| a.length <=> b.length}.length
    data.each{|row| row[max - 1] ||= nil}
  end
end

