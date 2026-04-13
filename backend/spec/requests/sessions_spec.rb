require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "POST /auth/login" do
    context "with valid credentials" do
      it "returns success and user data" do
        post "/auth/login", params: { user: { email: "test@example.com", password: "password123" } }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to eq("Logged in successfully.")
        expect(json["data"]["email"]).to eq("test@example.com")
      end

      it "returns a JWT token in the Authorization header" do
        post "/auth/login", params: { user: { email: "test@example.com", password: "password123" } }

        expect(response.headers["Authorization"]).to be_present
        expect(response.headers["Authorization"]).to match(/^Bearer /)
      end
    end

    context "with wrong password" do
      it "returns unauthorized" do
        post "/auth/login", params: { user: { email: "test@example.com", password: "wrongpassword" } }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with non-existent email" do
      it "returns unauthorized" do
        post "/auth/login", params: { user: { email: "nonexistent@example.com", password: "password123" } }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
