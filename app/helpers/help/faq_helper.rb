module Help::FaqHelper
  def secondary_nav
    breadcrumbs(link_to('Help', faq_path), 
                link_to('Frequently Asked Questions', '/faq'),
                action_name.capitalize) unless action_name == 'index'
  end

  def title
    "Frequently Asked Questions: #{params[:action_name]} | Help"
  end
end
