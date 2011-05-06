class Gradebook::MarksController < ApplicationController
  before_filter :login_required
  before_filter :find_mark, :only => [:edit, :update, :show]
  layout :by_user

  def create
    @mark = @section.reported_grades.create(params[:mark])
    if @mark.valid?
      redirect_to section_marks_url(@section), :notice => msg
    else
      @marks = @section.marks.map{|m| [m.description,m.id]}.unshift(['Insert first', 0])
      render :action => "new"
    end
  end

  def destroy
    @mark = @section.reported_grades.find(params[:id])
    @mark.destroy
    respond_to do |format|
      format.html{ redirect_to section_marks_url(@section), :notice => msg }
      format.js{render :update do |page|
          page.redirect_to section_marks_url(@section), :notice => msg
      end}
    end
    #note deleting won't automatically change grades that have been calculated based on the deleted grade
  end

  def edit
    @marks = @mark.milestones.group_by(&:rollbook_entry_id)
    set_edit_variables
    render :action => 'calculate' and return if params[:calculate]
    set_select
  end

  def index
    @headers, @students = @section.marks, @section.students
    @milestones = @section.marks_by_student
    @milestones.each do |key,array|
      @milestones[key] = array.sort_by{|a| @headers.index(@headers.detect{|h| h.id==a.reported_grade_id})} rescue []
    end
  end

  def new
    @marks = @section.marks.map{|m| [m.description,m.id]}.unshift(['Insert first', 0])
    @mark = @section.reported_grades.build
  end

  def show
    @students = @section.students.for_mark(@mark)
    if @mark.description =~ /Marking/
      @section.reported_grade_id = @mark.id
      @point_distribution = @section.point_distribution
      @mp = @mark.marking_periods.find_by_track_id(@section.track_id)
    end
  end

  def update
    @marks = set_marks_by_commit
    redirect_to section_marks_path(@section) and return unless @marks
    if @marks.is_a? String
      action = @marks
      @marks = @mark.milestones.group_by(&:rollbook_entry_id)
      set_edit_variables
      render action and return
    end
    if @marks.all? {|grade| grade.valid? }
      redirect_to section_marks_url(@section), :notice => msg
    else
      @marks = @marks.group_by(&:rollbook_entry_id)
      set_edit_variables
      set_select
      render :action => "edit"
    end
  end

protected
    def authorized?
      @section = Section.includes([:teacher, :subject]).find(params[:section_id])
      @teacher = @section.teacher
      current_user == @teacher || (current_user.admin? && @section.belongs_to?(@school) && %w(index show).include?(action_name))
    end

    def find_mark
      @mark = ReportedGrade.where(["(reportable_type = ? AND reportable_id = ?) OR (reportable_type = ? AND reportable_id = ?)", 'Section', @section.id, 'Term', @section.term.id]).find(params[:id])
    end

    def set_edit_variables
      @students = @section.rollbook_entries.includes('student').order(:position)
      @all_marks = @section.marks
      @predecessor_rg = @all_marks[0...@all_marks.index(@mark)]
      @predecessors = @predecessor_rg.collect(&:milestones).flatten.group_by(&:rollbook_entry_id)
    end

    def set_marks_by_commit
      case params[:commit]
      when 'Average'
        @mark.average_of(params[:avg].keys, @section)
      when 'Combine'
        @mark.combine(params[:pts].keys, @section)
      when 'Reset'
        @mark.reset!(@section)
      when 'Weight'
        if params[:wt].values.map(&:to_f).sum == 100
          @mark.weight_by(params[:wt], @section)
        else
          flash[:error] = "<h2>Bad News</h2>If you want to calculate marks with a weighted average, make sure the weights add to 100%."
          'calculate'
        end
      when 'Save'
        Milestone.update(params[:marx].keys, params[:marx].values)
      when 'Update Mark'
        if @mark.update_attributes(params[:mark])
          flash[:notice] = "<h2>Good News</h2>#{@mark.description} has been updated."
          nil
        else
          set_select
          'edit'
        end
      end
    end

    def set_select
      @class_marks = (@section.marks - [@mark]).map{|m| [m.description,m.id]}.unshift(['Insert first', 0]) if @mark.reportable_type == 'Section'
    end
end

