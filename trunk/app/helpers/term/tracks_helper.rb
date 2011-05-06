module Term::TracksHelper

  def archive_note
    p "Remember that this track is scheduled to be archived on #{@track.archive.strftime('%Y-%m-%d')}. The last marking period must end before that date." unless @track.archive.nil?
  end

  def nav_for_action
    %w(new create).include?(action_name) ? 'New Track' : 'Edit Track'
  end

  def secondary_nav
    breadcrumbs admin_front_link, link_to_term, nav_for_action
  end

  def title
    case action_name
    when 'new', 'create'
      'New Track | Admin'
    when 'edit', 'update'
      'Edit Track | Admin'
    end
  end
end

