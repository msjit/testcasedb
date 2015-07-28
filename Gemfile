source 'http://rubygems.org'

gem 'rails', '4.2.3'
gem 'mysql2', group: :mysql
gem 'pg', group: :postgres

# Use this temporarily until we update all models to use strong paramters
gem 'protected_attributes'

# gem "unicorn", "~> 4.8.2"

gem 'sidekiq'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'coffee-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier'
  gem 'therubyracer', :platforms => :ruby
end

gem 'best_in_place'
gem 'jquery-fileupload-rails'
gem 'sass-rails'
gem 'bootstrap-sass', '~> 2.3.2.1'

gem "jquery-rails"
gem "jquery-ui-rails"

gem "less-rails" #Sprockets (what Rails 3.1 uses for its asset pipeline) supports LESS

gem 'rtf'
gem 'minitest'

# NO LONGER NEEDED in ruby 1.9
# gem 'fastercsv'
# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem "nifty-generators", :group => :development

#require 'mysql2'

gem "cocaine", "0.3.2"
gem "nokogiri"
gem "expectr", "~> 0.9.0"
gem 'paperclip', "~> 2.7.2"
gem "remotipart", "~> 1.0"
gem 'mime-types'

# Paperclip requires that ImageMagick is installed on the system

gem 'chosen-rails'

gem "spreadsheet"

gem "rake", '>=0.9.2'

gem 'authlogic'
gem 'omniauth'
gem 'omniauth-google-oauth2'
gem 'cancan'
gem 'redis-rails'

gem 'kaminari'

gem 'prawn', '~> 1.2.1'
gem 'prawn-table', '~> 0.1.0'

gem 'soap4r-ruby1.9'

gem 'simple_form'
gem 'roo'
# This gem is not directly used by the application
# However, it is common to automate items using this
# We simplify our clients' lives by including it in the package
gem 'selenium-client'

# Use unicorn as the web server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger (ruby-debug for Ruby 1.8.7+, ruby-debug19 for Ruby 1.9.2+)
# gem 'ruby-debug'
# gem 'ruby-debug19', :require => 'ruby-debug'

# Bundle the extra gems:
# gem 'bj'
# gem 'nokogiri'
# gem 'sqlite3-ruby', :require => 'sqlite3'
# gem 'aws-s3', :require => 'aws/s3'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
# group :development, :test do
#   gem 'webrat'
# end
# gem "mocha", :group => :test
gem 'blitz'
group :development, :test do
  gem 'rspec-rails', '~> 3.0.0'
  gem "factory_girl_rails"
  gem "capybara", '>= 2.2.0'
  gem 'database_cleaner'
end
