class Authentication < ActiveRecord::Base
  attr_accessible :provider, :uid, :user_id

  validates :user_id, :uid, :provider, :presence => true
  validates_uniqueness_of :uid, :scope => :provider
  
  belongs_to :user
end
