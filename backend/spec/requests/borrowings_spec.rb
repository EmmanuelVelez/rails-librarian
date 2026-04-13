require 'rails_helper'

RSpec.describe "Borrowings", type: :request do
  let!(:librarian) { create(:user, :librarian) }
  let!(:member) { create(:user) }
  let!(:book) { create(:book, total_copies: 3) }

  describe "GET /api/v1/borrowings" do
    before do
      create(:borrowing, user: member, book: book)
      other_member = create(:user)
      create(:borrowing, user: other_member, book: create(:book))
    end

    it "returns borrowings with pagination metadata for a librarian" do
      headers = auth_headers_for(librarian)

      get "/api/v1/borrowings", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
      expect(json["pagination"]).to be_present
      expect(json["pagination"]["page"]).to eq(1)
    end

    it "returns only own borrowings for a member" do
      headers = auth_headers_for(member)

      get "/api/v1/borrowings", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["user"]["id"]).to eq(member.id)
    end

    it "returns paginated borrowings for a librarian" do
      14.times { create(:borrowing, user: create(:user), book: create(:book)) }
      headers = auth_headers_for(librarian)

      get "/api/v1/borrowings", params: { page: 1, per_page: 10 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(10)
      expect(json["pagination"]["total_count"]).to eq(16)
      expect(json["pagination"]["total_pages"]).to eq(2)
      expect(json["pagination"]["next_page"]).to eq(2)
    end
  end

  describe "POST /api/v1/borrowings" do
    it "allows a member to borrow a book" do
      headers = auth_headers_for(member)

      expect {
        post "/api/v1/borrowings", params: { borrowing: { book_id: book.id } }, headers: headers
      }.to change(Borrowing, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["book"]["id"]).to eq(book.id)
      expect(json["data"]["user"]["id"]).to eq(member.id)
      expect(json["data"]["due_date"]).to be_present
      expect(json["data"]["returned_at"]).to be_nil
    end

    it "returns 403 when a librarian tries to borrow" do
      headers = auth_headers_for(librarian)

      post "/api/v1/borrowings", params: { borrowing: { book_id: book.id } }, headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 for a duplicate active borrowing" do
      create(:borrowing, user: member, book: book)
      headers = auth_headers_for(member)

      post "/api/v1/borrowings", params: { borrowing: { book_id: book.id } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]["message"]).to include("already has an active borrowing")
    end

    it "returns 422 when no copies are available" do
      book.update!(total_copies: 1)
      create(:borrowing, user: create(:user), book: book)
      headers = auth_headers_for(member)

      post "/api/v1/borrowings", params: { borrowing: { book_id: book.id } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]["message"]).to include("No available copies")
    end
  end

  describe "PUT /api/v1/borrowings/:id/return" do
    let!(:borrowing) { create(:borrowing, user: member, book: book) }

    it "allows a librarian to mark a return" do
      headers = auth_headers_for(librarian)

      put "/api/v1/borrowings/#{borrowing.id}/return", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["returned_at"]).to be_present
    end

    it "returns 403 when a member tries to mark a return" do
      headers = auth_headers_for(member)

      put "/api/v1/borrowings/#{borrowing.id}/return", headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 when the book has already been returned" do
      borrowing.update!(returned_at: Time.current)
      headers = auth_headers_for(librarian)

      put "/api/v1/borrowings/#{borrowing.id}/return", headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]["message"]).to include("already been returned")
    end
  end
end
