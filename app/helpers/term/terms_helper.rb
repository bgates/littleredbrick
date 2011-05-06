module Term::TermsHelper

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p "The term was created successfuly. The marking period dates were set to make all marking periods the same length, so they are probably wrong. To fix the marking period dates in a track, click the track number in the first column of the table below."
    when 'update'
      p "The daily schedule was updated."
    end
  end

  def schedule
    if @term.low_period.nil?
      p link_to('Set daily period schedule', edit_term_url(@term))
    else
      h2('Daily Schedule') +
      p("A normal school day runs from period #{@term.low_period}  to period #{@term.high_period}. #{link_to "Edit", edit_term_url(@term)}".html_safe)
    end
  end

  def secondary_nav
    if action_name == 'show'
      super
    else
      breadcrumbs(admin_front_link,
                  link_to('Term', term_path(@school.terms.last)), 
                  secondary_nav_terminal)
    end
  end

  def secondary_nav_terminal
    case controller.action_name
    when 'new', 'create'
      "New Term"
    when 'edit', 'update'
      "Edit"
    end
  end

  def term_link
    return if session[:initial]
    if @other_term
      title =  @other_term.id > @term.id ? 'Next Term' : 'Previous Term'
      h2(title) + link_to(term_name(@other_term), term_url(@other_term)) 
    else
      link_to 'Add new term', new_term_url
    end
  end

  def term_title
    term_name(@term).sub(/&#151;/,'-')
  end

  def title
    case action_name
    when 'show'
      "Term #{ term_title } | Admin"
    when 'edit', 'update'
      "Edit Term #{ term_title } | Admin"
    when 'new', 'create'
      'New Term | Admin'
    end
  end
end

