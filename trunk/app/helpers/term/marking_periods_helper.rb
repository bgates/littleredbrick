module Term::MarkingPeriodsHelper
  def secondary_nav
    breadcrumbs admin_front_link, link_to_term, "New Marking Period"
  end

  def title
    'New Marking Period | Admin'
  end

end

