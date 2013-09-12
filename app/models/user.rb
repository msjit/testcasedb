class User < ActiveRecord::Base
  acts_as_authentic do |c|
    c.merge_validates_length_of_password_field_options :minimum => 8
    c.logged_in_timeout = TestDB::Application.config.session_timeout.minutes 
  end
  
  attr_accessible :username, :email, :password, :first_name, :last_name, :password_confirmation, :role, :active, :time_zone, :product_ids
  validates :username, :presence => true
  validates :username, :uniqueness => true
  validates :email, :presence => true
  validates :role, :presence => true
  has_many :reports
  has_many :tasks
  has_many :schedule_users
  has_many :schedules, :through => :schedule_users
  has_many :product_users, :dependent => :destroy
  has_many :products, :through => :product_users
  
  def name_with_email
      "#{last_name}, #{first_name} - #{email}"
  end
end
