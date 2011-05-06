module ActionView
  module Helpers

  def datebocks_field(object_name, method, has_label=nil, show_help = true)
    if object_name=~/\[\]$/
      tag = InstanceTag.new(object_name, method, self)
      field = tag.to_input_field_tag('text', :maxlength => 10)
      calendar_ref = "#{tag.object_name}_#{tag.instance_variable_get(:@auto_index)}_#{tag.method_name}"
      label = has_label ? content_tag(:label, has_label, :for => calendar_ref) : ""
    else
      field = text_field(object_name, method, :size => 10)
      label = has_label ? "<label for = '#{object_name}'>#{has_label}</label>" : ""
      calendar_ref = object_name + '_' + method
    end
    help = show_help ? li(image_tag('icon-help.gif', :alt => 'Help', :title => 'Help', :id => "#{calendar_ref}Help", :class => 'hide')) : ""
    content_tag(:div, :class => "dateBocks") do
      label.html_safe +
      content_tag(:ul) do
        content_tag(:li){field} +
        content_tag(:li){image_tag('calendar.png', :alt => 'Calendar', :title => 'Calendar', :id => calendar_ref + 'Button', :class => 'hide') } +
        help
      end.html_safe +
      content_tag(:div, :id => "#{calendar_ref}Msg", :class => "dateBocksMessage"){"yyyy-mm-dd"}
    end
  end

  def datebocks_field_tag(name, value, has_label=nil, show_help = true, options = {})
    calendar_ref = options[:id].nil?? name : options[:id]
    help = show_help ? li(image_tag('icon-help.gif', :alt => 'Help', :title => 'Help', :id => calendar_ref + 'Help', :class => 'hide' )) : ""
    if options[:obj] && !options[:obj].errors[options[:method]].empty?
      options[:class] ||= ''
      options[:class] += ' fieldWithErrors'
    end
    label = has_label ? "<label for = '#{name}'>#{has_label}</label>" : ""
    field = text_field_tag name, value, options.merge(:size => 10).except!(:obj)
    content_tag(:div, :class => "dateBocks") do
      label.html_safe +
      content_tag(:ul) do
        content_tag(:li){field} +
        content_tag(:li){image_tag('calendar.png', :alt => 'Calendar', :title => 'Calendar', :id => calendar_ref + 'Button', :class => 'hide') } +
        help
      end.html_safe +
      content_tag(:div, :id => "#{calendar_ref}Msg", :class => "dateBocksMessage"){"yyyy-mm-dd"}
    end
  end
end
end

