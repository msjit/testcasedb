class UserSession < Authlogic::Session::Base
  # This model takes care of user login and sessions
  # Authlogic provides several important features
  # Of note, we use the active bollean value on the user to see if a user should be able to login
  generalize_credentials_error_messages true
  
  # After 10 failed logins, acount is locked
  consecutive_failed_logins_limit 5
  
  # Will not auto unlock. Will need to be reset by admin
  failed_login_ban_for=0
  
  # Allow api_key requests and user api_key as the variable for the key
  params_key :api_key
  
  # single_access_allowed_request_types 
  # only allow token access for xml requests
  single_access_allowed_request_types ["application/json",
                                       "application/xml"]
  
  # We now logout users after timeout
  logout_on_timeout true # default if false
  
end