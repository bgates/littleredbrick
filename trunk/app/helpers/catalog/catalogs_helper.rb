module Catalog::CatalogsHelper

  def button_label
    %w(new create).include?(action_name)? "Create Catalog" : "Update Catalog"
  end

  def msg(type = :notice)
    msg_head(type) + 
    case action_name
    when 'create'
      p("The catalog has been created with " + 
        "#{pluralize(@school.departments.length, 'department')}. At this point" +
        " you can let teachers set up and enroll students in their own" +
        " classes, or you can do it for them.")
    when 'update'
        p "The catalog was updated."
    end
  end

end
