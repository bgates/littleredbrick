class Superuser < Staffer

  has_many              :owned_forums, :class_name => 'Forum', :foreign_key => 'owner_id'
  before_create         :make_staffer_admin

  def admin?
    true
  end

  alias :revoke_admin :destroy

  def discussables
    %w(help)
  end

  def display_name
    "#{first_name} (Tech Support)"
  end

  def may_create_forum_for?(discussable)
    discussable.is_a?(School) &&
      %w(school admin staff parents help).include?(discussable.type)
  end

  def may_access_forum_for?(discussable)
    discussable.is_a?(Section) || (discussable.is_a?(School) &&
    %w(admin help school staff parents).include?(discussable.type))
  end

  def may_see?(section_or_teacher)
    true
  end
  
  def section_ids
    []
  end

  protected
  def make_staffer_admin
    roles << Role.find_or_create_by_title('admin') 
  end
end
