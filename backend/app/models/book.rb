class Book < ApplicationRecord
  GENRES = [
    "Fiction", "Dystopian", "Science", "Philosophy",
    "Science Fiction", "History", "Technology", "Fantasy", "Biography"
  ].freeze

  has_many :borrowings, dependent: :destroy

  validates :title, :author, presence: true
  validates :genre, presence: true, inclusion: { in: GENRES, message: "%{value} is not a valid genre" }
  validates :isbn, presence: true, uniqueness: true
  validates :total_copies, numericality: { greater_than_or_equal_to: 0 }

  def available_copies
    total_copies - borrowings.active.count
  end
end
