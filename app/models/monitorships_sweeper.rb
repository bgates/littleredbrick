class MonitorshipsSweeper < ActionController::Caching::Sweeper
  observe Monitorship
  
  def after_save(monitorship)
    FileUtils.rm_rf File.join(::Rails.root.to_s, 'public', 'users', monitorship.user_id.to_s)
  end
  
  alias_method :after_destroy, :after_save
end
