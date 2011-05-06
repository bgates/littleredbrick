module Beast::ModeratorsHelper

  def msg(type = :notice)
    "#{msg_head(type)}" + 
    case action_name
    when 'create', 'search'
      if type == :notice
        p "#{@user.display_name} #{msg_for_n_forums}"
      else
        p("No one with the name '#{params[:search]}' can take part in " +
          "this forum.")
      end
    when 'destroy'
      if type == :notice
        p("#{@moderatorship.display_name} is no longer a moderator for " +
          "the #{@forum.name} forum, and cannot edit or delete comments" +
          " made by other users.")
      else
        p "Since you created that forum, you must be a moderator for it."
      end
    when 'update'
      p "The moderator list has been updated."
    end
  end

  def msg_for_n_forums
    if params[:forums].present?
      "may now moderate the forum(s) you selected."
    else
      "has been added as moderator, and may now edit or remove posts made by other users."
    end
  end
   
  def msg_head(type)
    if type == :notice
      h2 'Good News'
    else
      case action_name
      when 'destroy'
        h2 'You can&#39;t do that'

      end
    end
  end

  def secondary_nav
    breadcrumbs discussable_front,
                discussable_link(@discussable),
                forum_link(@discussable, @forum), 'Edit Moderators'
  end

  def title
    "#{@forum.name} Forum Moderators | Discussions"
  end

end
