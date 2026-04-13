module Api
  module V1
    class BorrowingsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_borrowing, only: [:return]

      def index
        authorize Borrowing
        scope = policy_scope(Borrowing).includes(:book, :user)
        pagy, borrowings = pagy(scope, limit: per_page_param)

        render json: {
          status: { code: 200, message: "Borrowings retrieved successfully." },
          data: borrowings.map { |b| BorrowingSerializer.new(b).serializable_hash },
          pagination: pagination_meta(pagy)
        }, status: :ok
      end

      def create
        authorize Borrowing
        borrowing = current_user.borrowings.new(
          book_id: borrowing_params[:book_id],
          borrowed_at: Time.current
        )

        if borrowing.save
          render json: {
            status: { code: 201, message: "Book borrowed successfully." },
            data: BorrowingSerializer.new(borrowing).serializable_hash
          }, status: :created
        else
          render json: {
            status: { code: 422, message: "Book could not be borrowed. #{borrowing.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      def return
        authorize @borrowing, :return_book?

        if @borrowing.returned_at.present?
          render json: {
            status: { code: 422, message: "This book has already been returned." }
          }, status: :unprocessable_entity
          return
        end

        if @borrowing.update(returned_at: Time.current)
          render json: {
            status: { code: 200, message: "Book returned successfully." },
            data: BorrowingSerializer.new(@borrowing).serializable_hash
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "Book could not be returned. #{@borrowing.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      private

      def set_borrowing
        @borrowing = Borrowing.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: { code: 404, message: "Borrowing not found." }
        }, status: :not_found
      end

      def borrowing_params
        params.require(:borrowing).permit(:book_id)
      end

      def per_page_param
        (params[:per_page] || 10).to_i.clamp(1, 50)
      end
    end
  end
end
