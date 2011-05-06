module ChartHelper

  def google_chart(data)
    tag :img, src:"http://chart.apis.google.com/chart?#{data}"
  end

  def histogram(values, grade_scale)
    bins = grade_scale.map{|g| g[0]}
    distribution = bins.map{|bin| [bin, values.select{|v| bin.include?(v)}.size]}
    distribution.first[0] = "&lt;#{distribution.first[0].end}"
    distribution.last[0] = "&gt;#{distribution.last[0].begin}"
    distribution.map!{|range,val| [range.to_s.sub(/.*\.\.\./, ''), val]}
    grades = grade_scale.map{|g| g[1]}
    char_length = grades.join.length
    width = [[10*char_length, 20*grades.length].max, 220].min
    frequencies = distribution.map{|whatever| whatever[1]}
    google_chart "cht=bvs&chg=100,25,1,0&chf=bg,s,ffffff00&chco=66aebd&chbh=10&chd=t:#{frequencies.join(',')}&chds=0,#{frequencies.max}&chs=#{width}x100&chxt=x,y&chxl=0:|#{grades.join('|')}|1:|0|#{frequencies.max}"
  end

  def pie_chart(distribution)
    height = [distribution.values.length * 18 + 10, 82].min
    width = 200 #may still need js to reset this
    color_array = %w(0085ff bddfff 8fa8bf 307bbf 406280 80c2ff 000000)
    colors = distribution.values.select{|v| v > 0}.length
    google_chart "cht=p&chf=bg,s,ffffff00&chco=#{color_array[0,colors].join(',')}&chs=#{width}x#{height}&chd=t:#{distribution.values.join(',')}&chdl=#{distribution.keys.join('|')}"
  end

  def progression_graph(progression)
    google_chart "cht=lc&chd=t:#{progression.map{|g| grade_with_precision(g[:grade])}.join(',') }&chs=300x130&chco=66AEBD&chf=c,s,eeeeee&chxt=y&chg=1000,20,1,0"
  end

end
