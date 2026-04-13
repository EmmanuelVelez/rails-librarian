class DashboardPolicy < ApplicationPolicy
  def index?
    true
  end

  def librarian?
    user.librarian?
  end

  def member?
    user.member?
  end
end
