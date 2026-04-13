module Api
  module V1
    class DashboardController < ApplicationController
      before_action :authenticate_user!

      def index
        authorize :dashboard, :index?

        if current_user.librarian?
          render_librarian_dashboard
        else
          render_member_dashboard
        end
      end

      private

      def render_librarian_dashboard
        render json: {
          status: { code: 200, message: "Librarian dashboard retrieved successfully." },
          data: {
            total_books: Book.count,
            total_borrowings: Borrowing.count,
            active_borrowings: Borrowing.active.count,
            overdue_borrowings: Borrowing.overdue.count,
            due_today: Borrowing.due_today.count,
            books_available: Book.left_joins(:borrowings).group(:id)
              .having("books.total_copies - COUNT(borrowings.id) FILTER (WHERE borrowings.returned_at IS NULL) > 0")
              .count.size,
            overdue_members: Borrowing.overdue.includes(:user, :book).map { |b|
              {
                member_name: "#{b.user.first_name} #{b.user.last_name}",
                book_title: b.book.title,
                due_date: b.due_date
              }
            }
          }
        }, status: :ok
      end

      def render_member_dashboard
        user_borrowings = current_user.borrowings.includes(:book, :user)

        render json: {
          status: { code: 200, message: "Member dashboard retrieved successfully." },
          data: {
            active_borrowings: user_borrowings.active.map { |b| BorrowingSerializer.new(b).serializable_hash },
            overdue_borrowings: user_borrowings.overdue.map { |b| BorrowingSerializer.new(b).serializable_hash },
            borrowing_history_count: user_borrowings.where.not(returned_at: nil).count
          }
        }, status: :ok
      end
    end
  end
end
