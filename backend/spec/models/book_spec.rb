require 'rails_helper'

RSpec.describe Book, type: :model do
  describe "associations" do
    it { should have_many(:borrowings).dependent(:destroy) }
  end

  describe "validations" do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:author) }
    it { should validate_presence_of(:genre) }
    it { should validate_presence_of(:isbn) }

    it { should validate_numericality_of(:total_copies).is_greater_than_or_equal_to(0) }

    it { should validate_inclusion_of(:genre).in_array(Book::GENRES).with_message(/is not a valid genre/) }

    describe "isbn uniqueness" do
      subject { create(:book, isbn: "978-ABC-1234567") }

      it { should validate_uniqueness_of(:isbn) }
    end
  end

  describe "#available_copies" do
    it "returns total_copies when there are no active borrowings" do
      book = create(:book, total_copies: 5)

      expect(book.available_copies).to eq(5)
    end

    it "subtracts active borrowings from total_copies" do
      book = create(:book, total_copies: 3)
      create(:borrowing, book: book)
      create(:borrowing, book: book)

      expect(book.available_copies).to eq(1)
    end

    it "does not count returned borrowings" do
      book = create(:book, total_copies: 2)
      create(:borrowing, book: book, returned_at: 1.day.ago)

      expect(book.available_copies).to eq(2)
    end
  end
end
