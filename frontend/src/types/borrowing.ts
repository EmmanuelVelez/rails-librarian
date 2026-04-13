import type { Book } from "./book";

export interface BorrowingUser {
  id: number;
  email: string;
  first_name: string;
  last_name: string;
}

export interface Borrowing {
  id: number;
  book: Book;
  user: BorrowingUser;
  borrowed_at: string;
  due_date: string;
  returned_at: string | null;
}

export interface OverdueMember {
  member_name: string;
  book_title: string;
  due_date: string;
}

export interface LibrarianDashboard {
  total_books: number;
  total_borrowings: number;
  active_borrowings: number;
  overdue_borrowings: number;
  due_today: number;
  books_available: number;
  overdue_members: OverdueMember[];
}

export interface MemberDashboard {
  active_borrowings: Borrowing[];
  overdue_borrowings: Borrowing[];
  borrowing_history_count: number;
}
