# Be sure to restart your server when you modify this file.
if APP_CONFIG['redis'] == 'enabled'
  TestDB::Application.config.session_store :redis_store, :key =>  APP_CONFIG['session_key']
else
  TestDB::Application.config.session_store :cookie_store, :key =>  APP_CONFIG['session_key']
end

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# TestDB::Application.config.session_store :active_record_store
