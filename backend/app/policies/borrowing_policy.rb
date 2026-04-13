class BorrowingPolicy < ApplicationPolicy
  def index?
    true
  end

  def create?
    user.member?
  end

  def return_book?
    user.librarian?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.librarian?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
