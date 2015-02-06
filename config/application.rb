require File.expand_path('../boot', __FILE__)

require 'yaml'
APP_CONFIG = YAML.load(File.read(File.expand_path('../app_config.yml', __FILE__)))

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module TestDB
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)
    config.autoload_paths += %W(#{config.root}/lib)
    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    
    
    # This is from rails 3.
    # The include was breaking login with no password.
    # Overwrite field_error_proc to sue span instead of div
    # Code retrieved fro rabbitcreative 
    # ActionView::Base.field_error_proc = Proc.new do |html_tag, instance|
    #  if html_tag =~ /<label/
    #    html_tag
    #  else
    #    include ActionView::Helpers::RawOutputHelper
    #    raw %(<span class="field_with_errors">#{html_tag}</span>)
    # end
    # end
    
    
    # Configuration options for Testlink
    # Set true to allow testlink import.
    # Always set back to false when finished!
    config.testlink_allowed = false
    
    # Parameters to access testlink DB
    config.testlink_host = 'localhost'
    config.testlink_username = 'root'
    config.testlink_password = 'password'
    config.testlink_db_name = 'testlink'
    
    # Parameters used to configure users
    config.testlink_default_password = 'newPass'
    config.testlink_default_timezone = "Eastern Time (US & Canada)"
    
    # Configure session timeout in minutes
    # Default is 1 hour (60 minutes)
    config.session_timeout = 60
    
    if APP_CONFIG['redis'] == 'enabled'
      config.cache_store = :redis_store, "redis://#{APP_CONFIG['redis_host']}:#{APP_CONFIG['redis_port']}/0/cache", { expires_in: 90.minutes }
    end
    # SSL Enabled option
    config.ssl_enabled = true
    
    # Assets based config 
    config.assets.enabled = true
    config.assets.version = '1.1'
  end
end