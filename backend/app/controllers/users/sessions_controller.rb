class Users::SessionsController < Devise::SessionsController
  respond_to :json

  private

  def respond_with(resource, _opts = {})
    render json: {
      status: { code: 200, message: "Logged in successfully." },
      data: UserSerializer.new(resource).serializable_hash
    }, status: :ok
  end

  def respond_to_on_destroy
    if request.headers["Authorization"].present?
      begin
        token = request.headers["Authorization"].split(" ").last
        jwt_payload = JWT.decode(token, ENV["DEVISE_JWT_SECRET_KEY"]).first
        jti = jwt_payload["jti"]

        if JwtDenylist.exists?(jti: jti)
          current_user = nil
        else
          current_user = User.find(jwt_payload["sub"])
        end
      rescue JWT::DecodeError
        current_user = nil
      end
    end

    if current_user
      render json: {
        status: { code: 200, message: "Logged out successfully." }
      }, status: :ok
    else
      render json: {
        status: { code: 401, message: "Couldn't find an active session." }
      }, status: :unauthorized
    end
  end
end
