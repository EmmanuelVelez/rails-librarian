class ApplicationController < ActionController::API
  include Pundit::Authorization
  include Pagy::Backend

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    render json: {
      status: { code: 403, message: "You are not authorized to perform this action." }
    }, status: :forbidden
  end

  def pagination_meta(pagy)
    {
      page: pagy.page,
      per_page: pagy.limit,
      total_pages: pagy.pages,
      total_count: pagy.count,
      next_page: pagy.next,
      prev_page: pagy.prev
    }
  end
end
