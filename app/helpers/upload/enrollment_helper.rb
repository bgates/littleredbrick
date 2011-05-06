module Upload::EnrollmentHelper
  include Gradebook::EnrollmentHelper

  def nav_for_action
    [link_to('Enroll', new_section_enrollment_path(@section), :title => 'Click to enroll students one at a time'), 'Upload']
  end

  def title
    "#{@page_h1} | #{title_suffix}"
  end

  def title_suffix
    current_user.admin?? 'Teachers' : 'Sections'
  end
end

