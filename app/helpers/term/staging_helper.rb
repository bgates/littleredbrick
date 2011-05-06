module Term::StagingHelper

  def active?(link)
    "active" if case link
    when 'admin'
      !params[:subject].blank?
    when 'student'
      !params[:student].blank?
    when 'teacher'
      !params[:teacher].blank?
    when 'class'
      (current_user.is_a?(Teacher) && params[:student].blank?) || !params[:subject].blank? || (current_user.is_a?(Student) || current_user.is_a?(Parent))
    end
  end

  def no_sections_msg
    if @student
      if @student == current_user
        msg = 'You have not been enrolled in any sections for next term. Check back later.'
      else
        msg = "#{@student.first_name} has not been enrolled in any sections for next term."
        if current_user.admin?
          msg += " To enroll the student, find a #{link_to 'teacher', teachers_path(:term => 'future')} in whose class the student should be enrolled."
        elsif current_user.is_a?(Teacher)
          msg += " To enroll the student in one of your classes, #{link_to 'click here', term_staging_path(@term, :teacher_id => current_user)}."
        end
       
      end
    elsif @teacher
      if @teacher == current_user
        msg = "Your sections for the next term have not been entered into the database. If you know what your teaching schedule will be, enter it #{link_to 'here', new_teaching_load_path(@teacher, :term => 'future')}."
      else
        msg = "#{@teacher.display_name} has not been scheduled to teach any sections for the next term. If you know what #{@teacher.display_name}&#39;s teaching schedule will be, enter it #{link_to 'here', new_teaching_load_path(@teacher, :term => 'future')}."
      end
    else
      msg = "No sections of this subject have been created for the next term."
      msg += "To create a teaching assignments for that term, select a teacher name from #{link_to 'this list', teachers_path(:term => 'future')}." if current_user.admin?
    end
    msg.html_safe
  end

  def person_or_subject
    if @student
      @student.full_name
    elsif @teacher
      @teacher.display_name
    elsif @sections.empty?
      Subject.find(params[:subject]).name
    else
      @sections[0].name
    end
  end

  def secondary_nav #TODO: subj nav goes to catalog of future but dept of present
    if params[:subject]
      breadcrumbs(link_to('Catalog', departments_path(:term => 'future'),
      :title => 'Click to see enrollment in all subjects for next term'), 
                  link_to(@department.name, department_subjects_path(@department)),
                  "Next Term #{@subject.name} Enrollment") 
    elsif params[:student]
      breadcrumbs(link_to(@student.full_name, student_path(@student)),
                  'Next Term Class Enrollment')
    elsif params[:teacher]
      link = @sections.empty?? 
        link_to("#{@teacher.display_name}&#39;s Teaching Load", 
        new_teaching_load_path(@teacher, :term => 'future')) : 
        link_to('Edit ' + @teacher.display_name + '&#39;s Teaching Load', 
        edit_teaching_load_path(@teacher, :term => 'future'))
      breadcrumbs(link_to_if(current_user.admin?, 'Next Term: Teachers', teachers_path(:term => 'future'){normal_text 'Next Term: Teachers'}), link, "#{@teacher.display_name}&#39;s Class Enrollment")
    else
      breadcrumbs 'Next Term Enrollment'
    end
  end

  def set_or_edit
    @sections.empty?? 'set' : 'edit'
  end

  def teaching_load_link
    if (@teacher && current_user.admin?) || current_user == @teacher
      "Click #{the_link} to #{set_or_edit} #{his_or_your} 
      teaching assignment for the upcoming term.".html_safe
    end
  end

  def the_link
    if @sections.empty?
      link_to 'here', new_teaching_load_path(@teacher, :term => 'future')
    else
      link_to 'here', edit_teaching_load_path(@teacher, :term => 'future')
    end
  end

  def title
    if @subject
      "Next Term | #{@subject.name} | #{@department.name}"
    elsif @teacher
      "Next Term | #{@teacher.display_name}"
    else
      "Next Term | #{@student.full_name}"
    end
  end

end
