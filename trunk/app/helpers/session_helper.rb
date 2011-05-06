module SessionHelper

  def msg(type = :notice)
   case action_name
   when 'destroy'
     p "You have been logged out.  Thank you for using LittleRedBrick"[:logged_out_message]
   when 'update'
     if current_user.is_a?Parent
       p "To view grades for a different child, return to this page and select another of your children from the list to the right"
     else
       status, other = session[:admin] ? ["an administrator", "teacher"] :
                               ["a teacher", "administrator"]
       h2("You are logged in as #{status}") +
       p("Click the button on the right side of this page to switch back to the #{other} view") 
     end
   end
  end
end
