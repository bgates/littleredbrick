module Help::PageHelper

  def nav_for_action
    @page_title || "#{params[:controller_name].capitalize} #{params[:action_name].capitalize}"
  end
  def secondary_nav
    breadcrumbs link_to('Help', general_help_path), nav_for_action
  end

  def title       #TODO: standardize this - lots of @page_title assignments
    "Help for the #{params[:controller_name].capitalize} #{params[:action_name].capitalize} Page"
  end
end
