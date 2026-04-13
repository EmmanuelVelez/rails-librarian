FactoryBot.define do
  factory :book do
    title { Faker::Book.title }
    author { Faker::Book.author }
    genre { Book::GENRES.sample }
    isbn { Faker::Barcode.isbn }
    total_copies { 3 }
  end
end
