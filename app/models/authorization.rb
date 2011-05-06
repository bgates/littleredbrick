require 'digest/sha1'
class Authorization < ActiveRecord::Base
  belongs_to                :user
  belongs_to                :school
  attr_accessor             :password, :signup

  before_save               :encrypt_password
  validates_presence_of     :password,                   :if => :password_required?
  validates_confirmation_of :password,                   :if => :password_required?
  validates_presence_of     :password_confirmation,      :if => :password_required?

  validates_length_of       :login,    :within => 3..40

  validates_uniqueness_of   :login, :scope => :school_id

  def self.authenticate(login, password, school_id)
    auth = find_by_login_and_school_id(login, school_id, :include => :user) # need to get the salt
    if auth && auth.authenticated?(password)
      last_login = auth.user.logins.create
      auth.user.update_attribute(:last_login, last_login.created_at)
      auth.user
    else
      nil
    end
  end

  def encrypt(password)
    Digest::SHA1.hexdigest("--#{salt}--#{password}--")
  end

  def authenticated?(password)
    crypted_password == encrypt(password)
  end

  def reset_login_key
    # this is not currently honored
    #self.login_key_expires_at = Time.now.utc+1.year
    self.login_key = Digest::SHA1.hexdigest(Time.now.to_s + crypted_password.to_s + rand(123456789).to_s).to_s
  end

  def reset_login_key!
    reset_login_key
    save!
    login_key
  end

  def encrypt_password
    return if password.blank?
    self.salt = Digest::SHA1.hexdigest("--#{Time.now.to_s}--#{login}--") if new_record?
    self.crypted_password = encrypt(password)
  end

  def bypass_code; crypted_password.reverse; end
  # Enable bulk addition of user information, automatically creating logins and passwords
  def add_default_attributes(user)
    self.school_id = user.school_id
    if user.first_name.blank? || user.last_name.blank?
      self.password, self.password_confirmation = 'password', 'password'
      self.login = user.id_number.to_s
    else
      return if self.password && self.password_confirmation && self.login
      self.login ||= user.first_name.downcase + user.last_name.downcase
      self.password = self.password_confirmation = login
    end
  end
  protected

  def password_required?
    crypted_password.blank? || !password.blank?
  end

end
