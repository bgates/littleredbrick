class PostsSweeper < ActionController::Caching::Sweeper
  observe Post
  
  def after_save(post)
    FileUtils.rm_rf File.join(Rails.root, 'public', 'forums', post.forum_id.to_s, 'posts.rss')
    FileUtils.rm_rf File.join(Rails.root, 'public', 'forums', post.forum_id.to_s, 'topics', "#{post.topic_id}.rss")
    FileUtils.rm_rf File.join(Rails.root, 'public', 'users')
    FileUtils.rm_rf File.join(Rails.root, 'public', 'posts.rss')
  end
  
  alias_method :after_destroy, :after_save
end
