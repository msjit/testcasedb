Rails.application.config.middleware.use OmniAuth::Builder do
  if Setting.find_by_name('Google Auth enabled') && Setting.find_by_name('Google Auth enabled').value
    provider :google_oauth2, Setting.find_by_name('Google Auth Client ID').value, Setting.find_by_name('Google Auth Secret').value
  end
end