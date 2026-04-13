require 'rails_helper'

RSpec.describe Borrowing, type: :model do
  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:book) }
  end

  describe "validations" do
    it { should validate_presence_of(:borrowed_at) }
    it { should validate_presence_of(:due_date) }
  end

  describe "auto due_date" do
    it "sets due_date to 14 days after borrowed_at when not provided" do
      borrowing = create(:borrowing, borrowed_at: Time.zone.parse("2026-04-01 10:00"), due_date: nil)

      expect(borrowing.due_date).to eq(Date.parse("2026-04-15"))
    end

    it "does not override an explicitly provided due_date" do
      explicit_date = Date.parse("2026-05-01")
      borrowing = create(:borrowing, borrowed_at: Time.current, due_date: explicit_date)

      expect(borrowing.due_date).to eq(explicit_date)
    end
  end

  describe "no duplicate active borrowing" do
    it "prevents a second active borrowing for the same user and book" do
      user = create(:user)
      book = create(:book, total_copies: 5)
      create(:borrowing, user: user, book: book)

      duplicate = build(:borrowing, user: user, book: book)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:base]).to include("User already has an active borrowing for this book")
    end

    it "allows a new borrowing after the previous one is returned" do
      user = create(:user)
      book = create(:book, total_copies: 5)
      create(:borrowing, :returned, user: user, book: book)

      new_borrowing = build(:borrowing, user: user, book: book)
      expect(new_borrowing).to be_valid
    end
  end

  describe "available copies check" do
    it "is invalid when no copies are available" do
      book = create(:book, total_copies: 1)
      create(:borrowing, book: book)

      borrowing = build(:borrowing, book: book)
      expect(borrowing).not_to be_valid
      expect(borrowing.errors[:base]).to include("No available copies of this book")
    end

    it "is valid when copies are available" do
      book = create(:book, total_copies: 2)
      create(:borrowing, book: book)

      borrowing = build(:borrowing, book: book)
      expect(borrowing).to be_valid
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only borrowings where returned_at is nil" do
        active = create(:borrowing)
        create(:borrowing, :returned)

        expect(Borrowing.active).to eq([active])
      end
    end

    describe ".overdue" do
      it "returns active borrowings with due_date in the past" do
        overdue = create(:borrowing, :overdue)
        create(:borrowing)

        expect(Borrowing.overdue).to eq([overdue])
      end

      it "excludes returned borrowings even if due_date is past" do
        create(:borrowing, :overdue, returned_at: Time.current)

        expect(Borrowing.overdue).to be_empty
      end
    end

    describe ".due_today" do
      it "returns active borrowings with due_date of today" do
        due_today = create(:borrowing, borrowed_at: 14.days.ago, due_date: Date.current)
        create(:borrowing, borrowed_at: Time.current)

        expect(Borrowing.due_today).to eq([due_today])
      end
    end
  end
end
