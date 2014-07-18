Rails.application.config.middleware.use OmniAuth::Builder do
  begin
    if Setting.value('Google Auth enabled') == true
      provider :google_oauth2, Setting.value('Google Auth Client ID'), Setting.value('Google Auth Secret')
    end
  rescue
   #  puts "Settings table not defined yet"
  end
end
