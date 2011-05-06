module AccountUploadHelper

  def default_login
    "The default login and password for each account is simply the #{@type.chomp('s')}&#39;s full name. For instance, #{@default_user.full_name} has login and password (both) <code>#{@default_user.login}</code>, which s/he will be prompted to change on first log in to keep the account secure.".html_safe if @default_user
  end

  def default_user
    @saveable.detect{|u| u.authorization && u.has_default_login? }
  end

  def nondefault_login
    unless @nondefault.nil?
      p "Since you were asked to change a login for a #{@type.chomp('s')}, that account will not have the defaults. You will need to let that person know how to get into their account."
    end
  end

  def nondefault_parent
    unless @nondefault.nil? || @type != 'students'
      "Since you changed the account of a student named #{@nondefault.full_name}, that student&#39;s parents have initial login and password <code>#{@nondefault.login}_mother</code> and <code>#{@nondefault.login}_father</code>.".html_safe
    end
  end

  def nondefault_user
    @saveable.detect{|u| ! u.has_default_login? }
  end

  def parent_login
    if @type == 'students'
      if @default_user
        p "Parent accounts for each student&#39;s father and mother were created, with login and password of the form 'studentname_father' and 'studentname_mother'. For example, the initial login and password for #{@default_user.first_name}'s father is <code>#{@default_user.authorization.login + '_father'}</code>, which he will be prompted to change on first log in. #{nondefault_parent}".html_safe
      else
        p "Parent accounts were created based on the logins you chose for each student. Parents will be prompted to change them the first time they log in, but you must let them know what their logins and passwords are. #{nondefault_parent}"
      end
    end
  end

  def msg(sure_all_default = true)
    @default_user = default_user
    @nondefault = nondefault_user
    h2("Good News") +
    p("#{@saveable.length} #{@type} were saved. #{default_login}".html_safe) +
    "#{nondefault_login} #{parent_login}".html_safe + teacher_limit
  end

  def teacher_limit
    if @type == 'teachers' && !@school.may_add_more_teachers?
      teacher_limit_notice
    end
  end
end

