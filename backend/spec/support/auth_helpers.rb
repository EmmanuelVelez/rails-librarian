module AuthHelpers
  def auth_headers_for(user, password: "password123")
    post "/auth/login", params: { user: { email: user.email, password: password } }
    token = response.headers["Authorization"]
    { "Authorization" => token }
  end
end

RSpec.configure do |config|
  config.include AuthHelpers, type: :request
end
