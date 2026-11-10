# frozen_string_literal: true

# Padrão para desenvolvimento local (fora do Docker).
# Dentro do Docker Compose, REDIS_URL é sobrescrito para redis://redis:6379/0.
Sidekiq.configure_server do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }
end
