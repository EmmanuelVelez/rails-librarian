module Api
  module V1
    class BooksController < ApplicationController
      before_action :authenticate_user!
      before_action :set_book, only: [:show, :update, :destroy]

      def index
        authorize Book
        scope = Book.all
        if params[:q].present?
          query = "%#{params[:q]}%"
          scope = scope.where("title ILIKE ? OR author ILIKE ? OR genre ILIKE ?", query, query, query)
        end
        pagy, books = pagy(scope, limit: per_page_param)
        render json: {
          status: { code: 200, message: "Books retrieved successfully." },
          data: books.map { |book| BookSerializer.new(book).serializable_hash },
          pagination: pagination_meta(pagy)
        }, status: :ok
      end

      def show
        authorize @book
        render json: {
          status: { code: 200, message: "Book retrieved successfully." },
          data: BookSerializer.new(@book).serializable_hash
        }, status: :ok
      end

      def create
        authorize Book
        book = Book.new(book_params)

        if book.save
          render json: {
            status: { code: 201, message: "Book created successfully." },
            data: BookSerializer.new(book).serializable_hash
          }, status: :created
        else
          render json: {
            status: { code: 422, message: "Book could not be created. #{book.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @book

        if @book.update(book_params)
          render json: {
            status: { code: 200, message: "Book updated successfully." },
            data: BookSerializer.new(@book).serializable_hash
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "Book could not be updated. #{@book.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @book

        if @book.borrowings.active.any?
          render json: {
            status: { code: 422, message: "Cannot delete a book with active borrowings." }
          }, status: :unprocessable_entity
          return
        end

        @book.destroy
        render json: {
          status: { code: 200, message: "Book deleted successfully." }
        }, status: :ok
      end

      private

      def set_book
        @book = Book.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: { code: 404, message: "Book not found." }
        }, status: :not_found
      end

      def book_params
        params.require(:book).permit(:title, :author, :genre, :isbn, :total_copies)
      end

      def per_page_param
        (params[:per_page] || 10).to_i.clamp(1, 50)
      end
    end
  end
end
