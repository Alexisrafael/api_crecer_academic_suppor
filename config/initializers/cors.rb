# frozen_string_literal: true

# Be sure to restart your server when you modify this file.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      source_clean = source.to_s.chomp('/')

      # Orígenes permitidos por defecto (incluye dominios productivos conocidos y desarrollo)
      default_origins = [
        'https://client-crecer-academic-support.vercel.app',
        'http://localhost:5173',
        'http://localhost:3000',
        'http://127.0.0.1:5173',
        'http://localhost:4173'
      ]

      # Orígenes configurables vía variables de entorno (limpiando espacios y barras finales)
      env_origins = []
      %w[FRONTEND_URL ALLOWED_ORIGINS MOVIL_URL].each do |var_name|
        if ENV[var_name].present?
          env_origins.concat(ENV[var_name].to_s.split(',').map { |u| u.strip.chomp('/') })
        end
      end

      # Orígenes desde Rails credentials si aplican para el entorno actual
      credential_origins = [
        Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url),
        Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url2),
        Rails.application.credentials.dig(Rails.env.to_sym, :movil_url)
      ].compact.map { |u| u.to_s.chomp('/') }

      allowed_origins = (default_origins + env_origins + credential_origins).reject(&:blank?).uniq

      # 1. Coincidencia directa con orígenes permitidos
      return true if allowed_origins.include?(source_clean)

      # 2. Permitir cualquier subdominio de Vercel (*.vercel.app)
      return true if source_clean.match?(%r{\Ahttps://([a-zA-Z0-9-]+\.)*vercel\.app\z})

      # 3. IPs privadas locales para pruebas en móviles por WiFi (192.168.x.x o 10.x.x.x)
      return true if source_clean.match?(%r{\Ahttps?://(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?\z})

      # 4. En desarrollo permite cualquier puerto en localhost / 127.0.0.1
      if Rails.env.development? && source_clean.match?(%r{\Ahttps?://(localhost|127\.0\.0\.1)(:\d+)?\z})
        return true
      end

      false
    end

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ['Authorization'],
      credentials: true
  end
end
