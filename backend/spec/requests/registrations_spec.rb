require 'rails_helper'

RSpec.describe "Registrations", type: :request do
  let(:valid_params) do
    {
      user: {
        first_name: "John",
        last_name: "Doe",
        email: "john@example.com",
        password: "password123",
        password_confirmation: "password123"
      }
    }
  end

  describe "POST /auth/register" do
    context "with valid parameters" do
      it "creates a new user and returns success" do
        expect {
          post "/auth/register", params: valid_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to eq("Signed up successfully.")
        expect(json["data"]["email"]).to eq("john@example.com")
        expect(json["data"]["first_name"]).to eq("John")
        expect(json["data"]["last_name"]).to eq("Doe")
      end

      it "returns a JWT token in the Authorization header" do
        post "/auth/register", params: valid_params
        expect(response.headers["Authorization"]).to be_present
        expect(response.headers["Authorization"]).to match(/^Bearer /)
      end

      it "defaults the role to member" do
        post "/auth/register", params: valid_params
        json = JSON.parse(response.body)
        expect(json["data"]["role"]).to eq("member")
      end
    end

    context "with missing first_name" do
      it "returns unprocessable entity" do
        params = valid_params.deep_dup
        params[:user].delete(:first_name)
        post "/auth/register", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to include("First name")
      end
    end

    context "with duplicate email" do
      before { create(:user, email: "john@example.com") }

      it "returns unprocessable entity" do
        post "/auth/register", params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to include("Email")
      end
    end

    context "with password too short" do
      it "returns unprocessable entity" do
        params = valid_params.deep_dup
        params[:user][:password] = "short"
        params[:user][:password_confirmation] = "short"
        post "/auth/register", params: params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["status"]["message"]).to include("Password")
      end
    end
  end
end
