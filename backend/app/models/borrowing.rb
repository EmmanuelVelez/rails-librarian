class Borrowing < ApplicationRecord
  belongs_to :user
  belongs_to :book

  validates :borrowed_at, presence: true
  validates :due_date, presence: true

  validate :no_duplicate_active_borrowing, on: :create
  validate :copies_available, on: :create

  before_validation :set_due_date, on: :create

  scope :active, -> { where(returned_at: nil) }
  scope :overdue, -> { active.where("due_date < ?", Date.current) }
  scope :due_today, -> { active.where(due_date: Date.current) }

  private

  def set_due_date
    self.due_date ||= (borrowed_at + 14.days).to_date if borrowed_at.present?
  end

  def no_duplicate_active_borrowing
    if Borrowing.active.exists?(user_id: user_id, book_id: book_id)
      errors.add(:base, "User already has an active borrowing for this book")
    end
  end

  def copies_available
    return unless book

    if book.available_copies <= 0
      errors.add(:base, "No available copies of this book")
    end
  end
end
