module SectionPreparation
  protected
  
  def find_marking_period
    @marking_periods = find_from_track
    @mp_position = (params[:marking_period] || Track.current_marking_period(@marking_periods).position).to_i
    @n_mps = @marking_periods.length
  end

  def find_from_track
    return MarkingPeriod.find_all_by_track_id(@section.track_id) unless @section.nil?
    return MarkingPeriod.find_all_by_track_id(@sections.first.track_id) unless @sections.blank?
    params[:term].blank?? @school.current_term.tracks[0].marking_periods : @school.terms[1].tracks[0].marking_periods
  end

  def prepare_section_data
    find_marking_period
    if @section
      @section.reported_grade_id = @marking_periods.detect{|mp| mp.position == @mp_position}.reported_grade_id
      @section[:mps] = @marking_periods.map(&:position)
    end
    if @sections
      @sections.each do |s|
        mp = s.track_id == @sections.first.track_id ? @marking_periods.detect{|mp| mp.position == @mp_position} : MarkingPeriod.find_by_track_id_and_position(s.track_id, @mp_position)
        s.reported_grade_id = mp.reported_grade_id
      end
    end
  end
end
