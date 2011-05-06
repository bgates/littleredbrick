module Gradebook::SeatingChartHelper

  def msg(type = :notice)
    h2("Good News") + p("Your seating chart has been created.")
  end

  def nav_for_action
    case action_name
    when 'new', 'create'
      "New Seating Chart"
    when 'edit', 'update'
      [link_to('Seating Chart', section_seating_chart_path(@section),
      :title => 'Click to see the current seating chart for this class'),
      'Edit']
    when 'show'
      "Seating Chart"
    end
  end

  def selected_for(rollbook_entries, x, y)
    if rbe = rollbook_entries.detect{|r| r.x == x && r.y == y}
      rbe.id
    elsif rollbook_entries.length > y * (rollbook_entries.length ** 0.5).ceil + x
      rollbook_entries[y * (rollbook_entries.length ** 0.5).ceil + x ].id
    else
      nil
    end
  end

  def secondary_nav
    breadcrumbs teacher_page_link, sections_front, 
                section_page_link, nav_for_action
  end

  def title
    "#{@page_h1} | #{title_suffix}"
  end

  def title_suffix
    current_user.admin?? 'Teachers' : 'Sections'
  end
end
