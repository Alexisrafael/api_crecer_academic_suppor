# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      # Orígenes permitidos por defecto en desarrollo local
      dev_origins = [
        'http://localhost:5173',
        'http://localhost:3000',
        'http://127.0.0.1:5173',
        'http://localhost:4173'
      ]

      # Orígenes configurables vía variables de entorno (acepta URLs separadas por comas)
      env_origins = []
      %w[FRONTEND_URL ALLOWED_ORIGINS MOVIL_URL].each do |var_name|
        if ENV[var_name].present?
          env_origins.concat(ENV[var_name].to_s.split(',').map(&:strip))
        end
      end

      # Orígenes desde Rails credentials si aplican para el entorno actual
      credential_origins = [
        Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url),
        Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url2),
        Rails.application.credentials.dig(Rails.env.to_sym, :movil_url)
      ].compact

      allowed_origins = (dev_origins + env_origins + credential_origins).reject(&:blank?).uniq

      # En desarrollo permite cualquier puerto en localhost / 127.0.0.1
      if Rails.env.development? && source.to_s.match?(%r{\Ahttps?://(localhost|127\.0\.0\.1)(:\d+)?\z})
        true
      else
        allowed_origins.include?(source)
      end
    end

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ['Authorization'],
      credentials: true
  end
end
