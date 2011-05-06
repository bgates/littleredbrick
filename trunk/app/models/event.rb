class Event < ActiveRecord::Base
  belongs_to :creator, :class_name => 'User', :foreign_key => 'creator_id'
  validates_presence_of :date, :message => "must be present"
  validates_presence_of :name, :message => "must be present"

  def audience
    case invitable_type
    when 'User'
      User.find(invitable_id).is_a?(Student) ? 'you and your parents' : 'no one but you'
    when 'School'
      'everyone in the school'
    when 'Teachers'
      'every teacher in the school'
    when 'Staff'
      'all staff members'
    when 'Admin'
      'all non-credentialed staff members'
    when 'Family'
      'everyone in your family'
    when 'Section'
      s = Section.find(invitable_id)
      if s.time
        "everyone in your period #{s.time} #{s.name} class"
      else
        "everyone in your #{s.name} class"
      end
    end
  end

  def editable_by?(user)
    user.id == creator_id
  end

  def self.for_family(parents, start, finish)
    where(["invitable_type = 'Family' AND creator_id IN (?) #{date_clause}", parents, start, finish])
  end

  def self.for_person(id, start, finish)
    where(["invitable_type = 'User' AND invitable_id = ? #{date_clause}", id, start, finish])
  end

  def self.for_sections(start, finish, section_ids)
    where(["invitable_type = 'Section' AND invitable_id IN (?) #{date_clause}", section_ids, start, finish]) 
  end

  def self.for_school(school, start, finish)
    where(["invitable_type = 'School' AND invitable_id = ? AND date BETWEEN ? AND ?", school, start, finish]) 
  end

  def self.for_staff(school, start, finish)
    where(["invitable_type IN (?) AND invitable_id = ? #{date_clause}", %w(Teachers Staff), school, start, finish])
  end

  def year; date.year; end

  def month; date.month; end

  def viewable_by?(user)
    case invitable_type
    when 'User'
      user.may_view_personal_events_for?(creator_id)
    when 'School'
      invitable_id == user.school_id
    when 'Section'
      user.section_ids.include?(invitable_id)
    when 'Teachers'
      user.is_a?(Teacher) && invitable_id == user.school_id
    when 'Staff'
      user.is_a?(Staffer) && invitable_id == user.school_id
    when 'Family'
      user.may_view_family_events_for?(invitable_id)
    end
  end

  def unique_id
    "#{invitable_id}#{invitable_type}"
  end

  protected

    def self.date_clause
      "AND date BETWEEN ? AND ?"
    end
end

