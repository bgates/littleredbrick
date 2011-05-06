module BifurcatedRoutesHelper

  ['new_', 'edit_', ''].each do |prefix|
    %w(path url).each do |suffix|
      define_method("#{prefix}teaching_load_#{suffix}".to_sym) do |teacher, options = {}|
        if current_user.admin?
          super(teacher, options)
        else
          send("#{prefix}personal_teaching_load_#{suffix}", options)
        end
      end
    end
  end

  %w(path url).each do |suffix|
    define_method "department_subjects_#{suffix}".to_sym do |dept, options = {}|
      if current_user.admin?
        super(dept, options)
      else
        params[:section_id] ||= @section
        send("section_department_#{suffix}", params[:section_id], options)
      end
    end

    ['edit_', ''].each do |prefix|
      define_method "#{prefix}section_#{suffix}".to_sym do |section, options = {}|
        if current_user.admin?
          send("#{prefix}teacher_section_#{suffix}", section.teacher, section, options)
        else
          super(section, options)
        end
      end
    end

    %w(assignments marks assignments_performance attendance).each do |action|
      define_method "section_#{action}_#{suffix}".to_sym do |section, options = {}|
        if current_user.admin?
          send "teacher_section_#{action}_#{suffix}", section.teacher, section, options
        else
          super(section, options)
        end
      end
    end

    %w(assignment mark).each do |action|
      define_method "section_#{action}_#{suffix}".to_sym do |section, item, options = {}|
        if current_user.admin?
          send "teacher_section_#{action}_#{suffix}", section.teacher, section, item, options
        else
          super(section, item, options)
        end
      end
    end
  end

end
