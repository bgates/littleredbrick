class Staffer < User

  has_many              :owned_forums, :class_name => 'Forum', :foreign_key => 'owner_id'
  before_create         :set_admin

  def admin?
    true
  end

  alias :revoke_admin :destroy

  def discussables
    %w(school admin staff)
  end

  def display_name
    title.nil?? last_name : "#{title} #{last_name}"
  end

  def may_create_forum_for?(discussable)
    discussable.is_a?(School) &&
    ['school', 'admin', 'staff', 'parents'].include?(discussable.type)
  end

  def may_access_forum_for?(discussable)
    discussable.is_a?(Section) || (discussable.is_a?(School) &&
    ['admin', 'help', 'school', 'staff', 'parents'].include?(discussable.type))
  end

  #call Event.all twice so index can be used in sql call
  def all_events(start, finish, include_assignments = false, child = nil) # last param used in student & teacher
    tracks = school.current_term.tracks
    (universal_events(start, finish, tracks) + 
    Event.where(["invitable_type = 'Staff' AND invitable_id = ? AND date BETWEEN ? AND ?", school_id, start, finish]) +                               
    Event.where(["invitable_type = 'Teachers' AND creator_id = ? AND date BETWEEN ? AND ?", id, start, finish])).sort_by{|event|event.date} 
    #(audience_type == Group && groups.map(&:id).include?(audience_id)
  end

  def may_see?(section_or_teacher)
    true
  end
  
  def section_ids
    []
  end

  protected
    def set_admin
      roles << Role.find_or_create_by_title('admin') unless self.is_a?(Teacher)
    end
end
