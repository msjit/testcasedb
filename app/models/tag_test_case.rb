class TagTestCase < ActiveRecord::Base
  belongs_to :test_case
  belongs_to :tag
end