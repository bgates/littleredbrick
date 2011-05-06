module AccountsHelper
  def secondary_nav
    ''
  end

  def back_or_home_link
    if flash[:show_initial_layout]
      link_to 'Skip', home_path
    else
      link_to 'Cancel', session[:return_to]
    end
  end

  def first_time_parent
    " Since you have just logged in for the first time using a child&#8217;s name, it is normal to see only that child on the list." if @first
  end

  def parent_gender(f)
    if @user.last_name == '_father'
      hidden_field_tag 'user[gender]', 'father'
    #elsif @user.last_name == '_mother'
    #  "#{hidden_field_tag :gender, 'mother'}"
    else
      content_tag :p, "If you are adding names of more children, indicate whether you are their:" + 
      content_tag(:label, f.radio_button(:gender, 'father') + 'Father ',
                  :class => 'radio') +
      content_tag(:label, f.radio_button(:gender, 'mother') + 'Mother ',
                  :class => 'radio')
    end
  end

  def remove_children
    unless @user.children.length == 1 
      "remove any students who are not your children, " 
    end
  end
end

