class Moderatorship < ActiveRecord::Base
  belongs_to :forum
  belongs_to :user
  validates_uniqueness_of :user_id, :scope => :forum_id
  delegate :display_name, :to => :user
 
  def may_not_be_destroyed_for?(forum)
    user_id == forum.owner_id 
  end

  def self.search(query, params)
    case params[:discussable].klass.downcase
    when 'school'
      User.search(query, :school_id => params[:school_id])
    when 'section'
      params[:discussable].students.where(['LOWER(last_name) ILIKE :q OR LOWER(first_name) ILIKE :q', {:q => query << '%'}])
    when 'staff'
      Staffer.search(query, :school_id => params[:school_id]) + Teacher.search(query, :school_id => params[:school_id])
    when 'teachers'
      Teacher.search(query, :school_id => params[:school_id])
    when 'admin'
      Staffer.search(query, :school_id => params[:school_id], :conditions => ["type <> 'Teacher'"])#.reject{|s| s.type == 'Teacher'}
    when 'parents'
      Parent.search(query, :school_id => params[:school_id]) + Staffer.search(query, :school_id => params[:school_id]) + Teacher.search(query, :school_id => params[:school_id])
    end
  end

end

