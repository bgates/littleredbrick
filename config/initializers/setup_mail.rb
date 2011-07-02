ActionMailer::Base.smtp_settings = {
  :address              => "smtp.gmail.com",
  :port                 => 587,
  :domain               => "littleredbrick.com",
  :user_name            => "welcome@littleredbrick.net",
  :password             => "ZCTu8<9Z",
  :authentication       => "plain",
  :enable_starttls_auto => true
}
