class Monitorship < ActiveRecord::Base
  belongs_to :user
  belongs_to :topic

  def self.deactivate(topic)
    find(topic).update_attribute(:active, false) 
  end

  def self.monitoring?(topic)
    where(['topic_id = ? and active = ?', topic.id, true]).present?
  end
end
