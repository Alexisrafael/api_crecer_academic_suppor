require_relative 'config/environment'
app = Rails.application
env = Rack::MockRequest.env_for(
  "/api/v1/auth/login",
  "REQUEST_METHOD" => "POST",
  "CONTENT_TYPE" => "application/json",
  input: '{"email":"admin@ejemplo.com","password":"password123"}'
)
status, headers, body = app.call(env)
puts "Status: #{status}"
puts "Headers: #{headers.inspect}"
