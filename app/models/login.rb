class Login < ActiveRecord::Base
  belongs_to :user

  def to_s
    created_at.strftime("%b %d %Y")
  end
end
