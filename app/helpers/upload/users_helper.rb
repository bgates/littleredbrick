module Upload::UsersHelper
  include People::EnterHelper

  def active?(link)
    "active" if link == 'teacher'
  end

  def secondary_nav
    breadcrumbs collection, link_to('Multiple', enter_multiple_path),
      "Upload #{params[:id].capitalize}"
  end
end
