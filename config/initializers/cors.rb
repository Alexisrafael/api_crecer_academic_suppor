# Be sure to restart your server when you modify this file.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(
      *[
        ENV['FRONTEND_URL'],
        ENV['MOVIL_URL'],
        Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url),
        Rails.application.credentials.dig(Rails.env.to_sym, :frontend_url2),
        Rails.application.credentials.dig(Rails.env.to_sym, :movil_url)
      ].compact
    )

    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ["Authorization"],
      credentials: true
  end
end
