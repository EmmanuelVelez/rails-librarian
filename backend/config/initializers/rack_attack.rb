class Rack::Attack
  # Strict throttle on login: 5 requests per 20 seconds per IP
  throttle("auth/login", limit: 5, period: 20.seconds) do |req|
    req.ip if req.path == "/auth/login" && req.post?
  end

  # Strict throttle on registration: 3 requests per 60 seconds per IP
  throttle("auth/register", limit: 3, period: 60.seconds) do |req|
    req.ip if req.path == "/auth/register" && req.post?
  end

  # Catch-all for all /auth/* endpoints: 20 requests per 60 seconds per IP
  throttle("auth/all", limit: 20, period: 60.seconds) do |req|
    req.ip if req.path.start_with?("/auth")
  end

  self.throttled_responder = lambda do |_req|
    body = {
      status: { code: 429, message: "Too many requests. Please try again later." }
    }.to_json

    [429, { "Content-Type" => "application/json" }, [body]]
  end
end
