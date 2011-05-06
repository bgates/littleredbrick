module Upload::GradesHelper
  
  def secondary_nav
    breadcrumbs sections_front,
                section_link(@section, @section.name_and_time(false)), 
                link_to('Gradebook', section_gradebook_path(@section), 
                :title => "Click to see the gradebook for #{@section.name_and_time}"), "Upload Grades"
  end

  def title
    "#{@page_h1} | Sections"
  end
end

