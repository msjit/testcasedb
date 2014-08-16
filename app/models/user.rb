class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.merge_validates_length_of_password_field_options :minimum => 8
    c.logged_in_timeout = TestDB::Application.config.session_timeout.minutes 
  end
  
  scope :active, where(:active=> true)
  attr_accessible :username, :email, :password, :first_name, :last_name, :password_confirmation, :role, :active, :time_zone, :product_ids
  validates :username, :presence => true
  validates :username, :uniqueness => true
  validates :email, :presence => true
  validates :role, :presence => true
  has_many :authentications, :dependent => :destroy
  has_many :reports
  has_many :tasks
  has_many :schedule_users
  has_many :schedules, :through => :schedule_users
  has_many :product_users, :dependent => :destroy
  has_many :products, :through => :product_users
  
  def name_with_email
      "#{last_name}, #{first_name} - #{email}"
  end
  
  # Returns an authorization for a provider type
  def auth_for(auth_provider)
    self.authentications.where(:provider => auth_provider).first
  end
end
