module Gradebook::MarksHelper

  def calculation_description
    if first_mark
      if first_marking_period
        "If you have changed the first marking period values and would like to change them back, click the following link. "
      end
    else
      "It is possible to calculate #{@mark.description} values based on previous marks - for instance, averaging two marking period grades to get a semester mark, or computing a weighted average of two semesters and a final exam to derive a cumulative final. "
    end
  end

  def first_marking_period
    @mark.description =~/arking/
  end

  def first_mark
    @predecessor_rg.empty?
  end

  def initial_empty_header
    if @headers.empty?
      header_row(td 'Click the plus sign above to add assignments', :colspan => 5)      
    end
  end

  def initial_no_students
    header_row(td 'Click the plus sign below to add students',
               :colspan => [5, @headers.length + 4].max) if @students.empty?
  end

  def initial_instructions
    "#{initial_empty_header}#{initial_no_students}"
  end

  def header_row(content)
    tr content, :class => 'setup'
  end

  def msg(type = :notice)
    msg_head(type) + 
      case action_name
      when 'create'
        p "#{@mark.description} was added to the class."
      when 'destroy'
        p "#{@mark.description} has been removed from this class."
      when 'update'
        p "#{@mark.description} scores have been updated."
      end
  end

  def nav_for_action
    case action_name
    when 'new', 'create'
      "New Mark"
    when 'edit', 'update'
      [link_to(@mark.description, section_mark_path(@section, @mark), 
      :title => "See details on #{@mark.description}"), 'Edit']
    when 'show'
      @mark.description
    end
  end

  def nav_for_index
    link_to_unless action_name == 'index', 'Marks', 
    section_marks_path(@section), :title => 'See all the marks for this class'
  end

  def percentage_for(milestone)
    n = "#{number_with_precision(milestone.grade, :precision => 1)}"
    n.to_i > 0 ? n + '%' : n
  end

  def secondary_nav
    breadcrumbs teacher_section_gradebook_links, nav_for_index, nav_for_action
  end

  def title
    "#{title_prefix} #{title_suffix}"
  end

  def title_prefix
    case action_name
    when 'index'
      "#{teachers}#{@section.name} Marks"
    when 'show'
      "#{teachers}#{@section.name} #{@mark.description} Marks"
    when 'edit', 'update'
      "Edit #{@section.name} #{@mark.description} Marks"
    when 'new', 'create'
      "New #{@section.name} Mark"
    end
  end

  def title_suffix
    current_user.admin?? '| Teachers' : '| Sections'
  end
end

