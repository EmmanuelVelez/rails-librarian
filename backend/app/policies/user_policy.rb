class UserPolicy < ApplicationPolicy
  def index?
    user.librarian?
  end

  def show?
    user.librarian? || user == record
  end

  def update?
    user.librarian? || user == record
  end

  def destroy?
    user.librarian?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.librarian?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
