puts "Seeding database..."

# --- Users ---
librarian = User.find_or_create_by!(email: "librarian@example.com") do |u|
  u.first_name = "Alice"
  u.last_name = "Morgan"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :librarian
end

member1 = User.find_or_create_by!(email: "member1@example.com") do |u|
  u.first_name = "Bob"
  u.last_name = "Smith"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :member
end

member2 = User.find_or_create_by!(email: "member2@example.com") do |u|
  u.first_name = "Carol"
  u.last_name = "Johnson"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :member
end

puts "  Created #{User.count} users"

# --- Books ---
books_data = [
  { title: "The Great Gatsby",        author: "F. Scott Fitzgerald", genre: "Fiction",         isbn: "978-0743273565", total_copies: 4 },
  { title: "To Kill a Mockingbird",   author: "Harper Lee",          genre: "Fiction",         isbn: "978-0061120084", total_copies: 3 },
  { title: "1984",                    author: "George Orwell",       genre: "Dystopian",       isbn: "978-0451524935", total_copies: 5 },
  { title: "A Brief History of Time", author: "Stephen Hawking",     genre: "Science",         isbn: "978-0553380163", total_copies: 2 },
  { title: "The Art of War",          author: "Sun Tzu",             genre: "Philosophy",      isbn: "978-1599869773", total_copies: 3 },
  { title: "Dune",                    author: "Frank Herbert",       genre: "Science Fiction",  isbn: "978-0441013593", total_copies: 4 },
  { title: "Sapiens",                 author: "Yuval Noah Harari",   genre: "History",         isbn: "978-0062316097", total_copies: 3 },
  { title: "Clean Code",              author: "Robert C. Martin",    genre: "Technology",      isbn: "978-0132350884", total_copies: 2 },
  { title: "The Hobbit",              author: "J.R.R. Tolkien",      genre: "Fantasy",         isbn: "978-0547928227", total_copies: 5 },
  { title: "Becoming",                author: "Michelle Obama",      genre: "Biography",       isbn: "978-1524763138", total_copies: 3 }
]

books = books_data.map do |attrs|
  Book.find_or_create_by!(isbn: attrs[:isbn]) do |b|
    b.title = attrs[:title]
    b.author = attrs[:author]
    b.genre = attrs[:genre]
    b.total_copies = attrs[:total_copies]
  end
end

puts "  Created #{Book.count} books"

# --- Borrowings ---
# Always recreate borrowings so relative dates stay accurate
Borrowing.destroy_all

gatsby, mockingbird, nineteen84, brief_history, art_of_war,
  dune, sapiens, clean_code, hobbit, becoming = books

# Member 1 (Bob Smith) — active, due today, overdue, returned
Borrowing.create!(user: member1, book: clean_code,  borrowed_at: 5.days.ago)
Borrowing.create!(user: member1, book: sapiens,     borrowed_at: 14.days.ago, due_date: Date.current)
Borrowing.create!(user: member1, book: nineteen84,  borrowed_at: 30.days.ago, due_date: 16.days.ago)
Borrowing.create!(user: member1, book: mockingbird,  borrowed_at: 40.days.ago, due_date: 26.days.ago, returned_at: 28.days.ago)
Borrowing.create!(user: member1, book: gatsby,       borrowed_at: 35.days.ago, due_date: 21.days.ago, returned_at: 22.days.ago)

# Member 2 (Carol Johnson) — active, due today, overdue, returned
Borrowing.create!(user: member2, book: dune,          borrowed_at: 2.days.ago)
Borrowing.create!(user: member2, book: hobbit,        borrowed_at: 14.days.ago, due_date: Date.current)
Borrowing.create!(user: member2, book: brief_history, borrowed_at: 25.days.ago, due_date: 11.days.ago)
Borrowing.create!(user: member2, book: art_of_war,    borrowed_at: 35.days.ago, due_date: 21.days.ago, returned_at: 22.days.ago)
Borrowing.create!(user: member2, book: becoming,      borrowed_at: 20.days.ago, due_date: 6.days.ago,  returned_at: 7.days.ago)

puts "  Created #{Borrowing.count} borrowings"
puts "    Active: #{Borrowing.active.count}"
puts "    Overdue: #{Borrowing.overdue.count}"
puts "    Due today: #{Borrowing.due_today.count}"
puts "    Returned: #{Borrowing.where.not(returned_at: nil).count}"
puts "Done!"
