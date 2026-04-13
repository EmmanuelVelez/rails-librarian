require 'rails_helper'

RSpec.describe "Logout", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "DELETE /auth/logout" do
    context "with a valid token" do
      it "logs out successfully" do
        headers = auth_headers_for(user)
        delete "/auth/logout", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to eq("Logged out successfully.")
      end
    end

    context "without a token" do
      it "returns unauthorized" do
        delete "/auth/logout"

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "after logout" do
      it "the token is no longer valid" do
        headers = auth_headers_for(user)
        delete "/auth/logout", headers: headers
        expect(response).to have_http_status(:ok)

        delete "/auth/logout", headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
