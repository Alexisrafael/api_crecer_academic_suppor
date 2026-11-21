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

      # En bloques de Ruby no se usa 'return' (provoca LocalJumpError).
      # Se evalúa la condición booleana directamente:
      allowed_origins.include?(source_clean) ||
        source_clean.match?(%r{\Ahttps://([a-zA-Z0-9-]+\.)*vercel\.app\z}) ||
        source_clean.match?(%r{\Ahttps?://(192\.168\.\d+\.\d+|10\.\d+\.\d+\.\d+)(:\d+)?\z}) ||
        (Rails.env.development? && source_clean.match?(%r{\Ahttps?://(localhost|127\.0\.0\.1)(:\d+)?\z}))
    end

    resource '*',
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ['Authorization'],
      credentials: true
  end
end
