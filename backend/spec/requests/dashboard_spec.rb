require 'rails_helper'

RSpec.describe "Dashboard", type: :request do
  let!(:librarian) { create(:user, :librarian) }
  let!(:member) { create(:user) }

  describe "GET /api/v1/dashboard" do
    context "as a librarian" do
      before do
        book1 = create(:book, total_copies: 3)
        book2 = create(:book, total_copies: 1)
        create(:borrowing, user: member, book: book1)
        create(:borrowing, :overdue, user: member, book: book2)
      end

      it "returns dashboard stats for a librarian" do
        headers = auth_headers_for(librarian)

        get "/api/v1/dashboard", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json["data"]
        expect(data["total_books"]).to eq(2)
        expect(data["total_borrowings"]).to eq(2)
        expect(data["active_borrowings"]).to eq(2)
        expect(data["overdue_borrowings"]).to eq(1)
      end

      it "includes overdue_members list with member name, book title, and due date" do
        headers = auth_headers_for(librarian)

        get "/api/v1/dashboard", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json["data"]
        expect(data["overdue_members"]).to be_an(Array)
        expect(data["overdue_members"].size).to eq(1)
        overdue = data["overdue_members"].first
        expect(overdue["member_name"]).to eq("#{member.first_name} #{member.last_name}")
        expect(overdue["book_title"]).to be_present
        expect(overdue["due_date"]).to be_present
      end
    end

    context "as a member" do
      before do
        book1 = create(:book, total_copies: 5)
        book2 = create(:book, total_copies: 5)
        book3 = create(:book, total_copies: 5)
        create(:borrowing, user: member, book: book1)
        create(:borrowing, :overdue, user: member, book: book2)
        create(:borrowing, :returned, user: member, book: book3)
      end

      it "returns dashboard data for a member" do
        headers = auth_headers_for(member)

        get "/api/v1/dashboard", headers: headers

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        data = json["data"]
        expect(data["active_borrowings"].size).to eq(2)
        expect(data["overdue_borrowings"].size).to eq(1)
        expect(data["borrowing_history_count"]).to eq(1)
      end
    end

    context "without authentication" do
      it "returns 401" do
        get "/api/v1/dashboard"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
