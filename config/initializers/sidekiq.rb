APP_CONFIG['redis'] == 'enabled'
  if Sidekiq.configure_server do |config|
    config.redis = { url: "redis://#{APP_CONFIG['redis_host']}:#{APP_CONFIG['redis_port']}/12" }
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: "redis://#{APP_CONFIG['redis_host']}:#{APP_CONFIG['redis_port']}/12" }
  end
end