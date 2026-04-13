require 'rails_helper'

RSpec.describe "Rate Limiting", type: :request do
  before do
    Rack::Attack.enabled = true
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after do
    Rack::Attack.enabled = false
    Rack::Attack.cache.store = Rails.cache
  end

  describe "POST /auth/login" do
    let!(:user) { create(:user, email: "throttle@example.com", password: "password123") }
    let(:login_params) { { user: { email: "throttle@example.com", password: "password123" } } }

    it "allows requests under the limit" do
      5.times { post "/auth/login", params: login_params }

      expect(response).not_to have_http_status(:too_many_requests)
    end

    it "returns 429 after exceeding the limit" do
      6.times { post "/auth/login", params: login_params }

      expect(response).to have_http_status(:too_many_requests)
      json = JSON.parse(response.body)
      expect(json["status"]["code"]).to eq(429)
      expect(json["status"]["message"]).to include("Too many requests")
    end
  end

  describe "POST /auth/register" do
    it "allows requests under the limit" do
      3.times do |i|
        post "/auth/register", params: {
          user: {
            first_name: "Test",
            last_name: "User#{i}",
            email: "throttle#{i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      expect(response).not_to have_http_status(:too_many_requests)
    end

    it "returns 429 after exceeding the limit" do
      4.times do |i|
        post "/auth/register", params: {
          user: {
            first_name: "Test",
            last_name: "User#{i}",
            email: "throttle#{i}@example.com",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      expect(response).to have_http_status(:too_many_requests)
      json = JSON.parse(response.body)
      expect(json["status"]["code"]).to eq(429)
      expect(json["status"]["message"]).to include("Too many requests")
    end
  end
end
