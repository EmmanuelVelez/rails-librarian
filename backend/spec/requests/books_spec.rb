require 'rails_helper'

RSpec.describe "Books", type: :request do
  let!(:librarian) { create(:user, :librarian) }
  let!(:member) { create(:user) }

  describe "GET /api/v1/books" do
    it "returns books with pagination metadata" do
      create_list(:book, 3)
      headers = auth_headers_for(member)

      get "/api/v1/books", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(3)
      expect(json["pagination"]).to be_present
      expect(json["pagination"]["page"]).to eq(1)
    end

    it "returns 401 for unauthenticated requests" do
      get "/api/v1/books"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns paginated results with metadata" do
      create_list(:book, 15)
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { page: 1, per_page: 10 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(10)
      expect(json["pagination"]["total_count"]).to eq(15)
      expect(json["pagination"]["total_pages"]).to eq(2)
      expect(json["pagination"]["next_page"]).to eq(2)
      expect(json["pagination"]["prev_page"]).to be_nil
    end

    it "returns the second page" do
      create_list(:book, 15)
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { page: 2, per_page: 10 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(5)
      expect(json["pagination"]["page"]).to eq(2)
      expect(json["pagination"]["prev_page"]).to eq(1)
      expect(json["pagination"]["next_page"]).to be_nil
    end

    it "defaults to page 1 when no page param is provided" do
      create_list(:book, 3)
      headers = auth_headers_for(member)

      get "/api/v1/books", headers: headers

      json = JSON.parse(response.body)
      expect(json["pagination"]["page"]).to eq(1)
    end
  end

  describe "GET /api/v1/books/:id" do
    let!(:book) { create(:book) }

    it "returns the book for an authenticated user" do
      headers = auth_headers_for(member)

      get "/api/v1/books/#{book.id}", headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["id"]).to eq(book.id)
      expect(json["data"]["title"]).to eq(book.title)
      expect(json["data"]["available_copies"]).to eq(book.total_copies)
    end

    it "returns 404 for a non-existent book" do
      headers = auth_headers_for(member)

      get "/api/v1/books/999999", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/v1/books" do
    let(:valid_params) do
      {
        book: {
          title: "The Great Gatsby",
          author: "F. Scott Fitzgerald",
          genre: "Fiction",
          isbn: "978-0743273565",
          total_copies: 5
        }
      }
    end

    it "allows a librarian to create a book" do
      headers = auth_headers_for(librarian)

      expect {
        post "/api/v1/books", params: valid_params, headers: headers
      }.to change(Book, :count).by(1)

      expect(response).to have_http_status(:created)
      json = JSON.parse(response.body)
      expect(json["data"]["title"]).to eq("The Great Gatsby")
      expect(json["data"]["isbn"]).to eq("978-0743273565")
    end

    it "returns 403 when a member tries to create a book" do
      headers = auth_headers_for(member)

      post "/api/v1/books", params: valid_params, headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 with missing required fields" do
      headers = auth_headers_for(librarian)

      post "/api/v1/books", params: { book: { title: "" } }, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]["message"]).to include("Title")
    end

    it "returns 422 with an invalid genre" do
      headers = auth_headers_for(librarian)
      params = valid_params.deep_dup
      params[:book][:genre] = "InvalidGenre"

      post "/api/v1/books", params: params, headers: headers

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]["message"]).to include("not a valid genre")
    end
  end

  describe "PATCH /api/v1/books/:id" do
    let!(:book) { create(:book) }

    it "allows a librarian to update a book" do
      headers = auth_headers_for(librarian)

      patch "/api/v1/books/#{book.id}", params: { book: { title: "Updated Title" } }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]["title"]).to eq("Updated Title")
    end

    it "returns 403 when a member tries to update a book" do
      headers = auth_headers_for(member)

      patch "/api/v1/books/#{book.id}", params: { book: { title: "Hacked" } }, headers: headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "DELETE /api/v1/books/:id" do
    let!(:book) { create(:book) }

    it "allows a librarian to delete a book" do
      headers = auth_headers_for(librarian)

      expect {
        delete "/api/v1/books/#{book.id}", headers: headers
      }.to change(Book, :count).by(-1)

      expect(response).to have_http_status(:ok)
    end

    it "returns 403 when a member tries to delete a book" do
      headers = auth_headers_for(member)

      delete "/api/v1/books/#{book.id}", headers: headers

      expect(response).to have_http_status(:forbidden)
    end

    it "returns 422 when the book has active borrowings" do
      create(:borrowing, book: book, user: member)
      headers = auth_headers_for(librarian)

      expect {
        delete "/api/v1/books/#{book.id}", headers: headers
      }.not_to change(Book, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      json = JSON.parse(response.body)
      expect(json["status"]["message"]).to include("active borrowings")
    end
  end

  describe "GET /api/v1/books?q=..." do
    before do
      create(:book, title: "Ruby Programming", author: "Matz", genre: "Technology")
      create(:book, title: "Python Cookbook", author: "David Beazley", genre: "Technology")
      create(:book, title: "The Hobbit", author: "J.R.R. Tolkien", genre: "Fantasy")
    end

    it "returns books matching by title" do
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { q: "Ruby" }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["title"]).to eq("Ruby Programming")
    end

    it "returns books matching by author" do
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { q: "Tolkien" }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(1)
      expect(json["data"].first["author"]).to eq("J.R.R. Tolkien")
    end

    it "returns books matching by genre" do
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { q: "Technology" }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(2)
    end

    it "returns an empty array when no books match" do
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { q: "Nonexistent" }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"]).to be_empty
    end

    it "paginates search results" do
      12.times { |i| create(:book, title: "Unique Paginated #{i}", genre: "Fiction") }
      headers = auth_headers_for(member)

      get "/api/v1/books", params: { q: "Unique Paginated", page: 1, per_page: 5 }, headers: headers

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["data"].size).to eq(5)
      expect(json["pagination"]["total_count"]).to eq(12)
      expect(json["pagination"]["total_pages"]).to eq(3)
    end
  end
end
