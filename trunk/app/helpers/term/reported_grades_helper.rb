module Term::ReportedGradesHelper
  def secondary_nav
    breadcrumbs admin_front_link, link_to_term, link_to_unless_current('Marks', term_reported_grades_path(@term)), ('Edit' if %w(edit update).include?(action_name))
  end

  def title
    case action_name
    when 'index'
      'Marks | Admin'
    when 'edit', 'update'
      'Edit Mark | Admin'
    end
  end

  def uneditable(grade)
    grade.description =~ /arking/ && (grade != @term.marking_periods.last || @term.marking_periods.length == 1)
  end
end

