# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
TestDB::Application.initialize!

Rails.logger = Logger.new(STDOUT)
Rails.logger.level = 0   # set to debug leve 0