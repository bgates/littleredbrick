class UserNotifier < ActionMailer::Base

  default :from => "auto-email@littleredbrick.com"
  
  def password_bypass(school, user)
    setup_email(user, school)
    @subject    += '| Login'
    @url = "http://#{school.domain_name}.littleredbrick.com/bypass/#{user.authorization.bypass_code}"
    mail(:to => user.email)
  end

  def welcome_email(school, user)
    setup_email(user, school)
    @subject = "Thanks for signing up with LittleRedBrick!"
    @url = "http://#{school.domain_name}.littleredbrick.com"
    mail(:to => user.email, :from => "welcome@littleredbrick.com")
  end

  def school_creation_notification(school, user)
    setup_email(user, school)
    @subject = "New school"
    mail(:to => "briandotgates@gmail.com")
  end
  
  protected
  def setup_email(user, school)
    @subject     = "LittleRedBrick "
    @sent_on     = Time.now
    @user, @school = user, school
  end
end
