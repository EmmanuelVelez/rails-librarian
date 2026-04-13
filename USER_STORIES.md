# User Stories — Library Management System

## Authentication & Authorization

**US-01: User Registration**
As a visitor, I want to register an account with my email and password so that I can access the library system.
- Acceptance Criteria:
  - User provides email, password, and password confirmation.
  - System rejects duplicate emails.
  - System returns a JWT token upon successful registration.

**US-02: User Login**
As a registered user, I want to log in with my credentials so that I can access my dashboard and perform actions.
- Acceptance Criteria:
  - User provides email and password.
  - System returns a JWT token on success.
  - System returns a 401 error on invalid credentials.

**US-03: User Logout**
As a logged-in user, I want to log out so that my session is terminated securely.
- Acceptance Criteria:
  - JWT token is invalidated on logout.
  - Subsequent requests with the old token are rejected.

---

## Book Management

**US-04: Add a Book (Librarian)**
As a librarian, I want to add a new book to the catalog so that members can discover and borrow it.
- Acceptance Criteria:
  - Book requires: title, author, genre, ISBN, and total copies.
  - ISBN must be unique.
  - Genre must be from a predefined list.
  - Only librarians can perform this action.

**US-05: Edit a Book (Librarian)**
As a librarian, I want to edit a book's details so that the catalog stays accurate and up to date.
- Acceptance Criteria:
  - All book fields are editable.
  - ISBN uniqueness is enforced on update.
  - Only librarians can perform this action.

**US-06: Delete a Book (Librarian)**
As a librarian, I want to delete a book from the catalog so that discontinued titles are removed.
- Acceptance Criteria:
  - Book is removed from the catalog.
  - Books with active borrowings cannot be deleted.
  - Only librarians can perform this action.

**US-07: Search Books**
As a user, I want to search for books by title, author, or genre so that I can find what I'm looking for.
- Acceptance Criteria:
  - Search accepts a query string and matches against title, author, and genre.
  - Search is case-insensitive.
  - Results return matching books with their availability (available copies).
  - Both librarians and members can search.

---

## Borrowing & Returning

**US-08: Borrow a Book (Member)**
As a member, I want to borrow an available book so that I can read it.
- Acceptance Criteria:
  - System records the borrowing date and sets the due date to 14 days later.
  - Available copies decrease by one.
  - Member cannot borrow a book they already have checked out.
  - Member cannot borrow a book with zero available copies.
  - Only members can perform this action.

**US-09: Return a Book (Librarian)**
As a librarian, I want to mark a borrowed book as returned so that it becomes available again.
- Acceptance Criteria:
  - System records the return date.
  - Available copies increase by one.
  - The borrowing record is marked as returned.
  - Only librarians can perform this action.

---

## Dashboards

**US-10: Librarian Dashboard**
As a librarian, I want to see an overview of the library so that I can manage operations effectively.
- Acceptance Criteria:
  - Shows total number of books in the catalog.
  - Shows total number of currently borrowed books.
  - Shows number of books due today.
  - Shows a list of members with overdue books (member name, book title, due date).

**US-11: Member Dashboard**
As a member, I want to see my borrowing activity so that I can track my books and due dates.
- Acceptance Criteria:
  - Shows a list of currently borrowed books with their due dates.
  - Highlights overdue books.

---

## API

**US-12: RESTful API Endpoints**
As a developer, I want well-structured API endpoints so that the frontend can interact with the system reliably.
- Acceptance Criteria:
  - `POST /auth/register` — register a new user.
  - `POST /auth/login` — authenticate and receive a JWT.
  - `DELETE /auth/logout` — invalidate the current session.
  - `GET /api/v1/books` — list all books (supports search params).
  - `POST /api/v1/books` — create a book (librarian only).
  - `GET /api/v1/books/:id` — show a single book.
  - `PUT /api/v1/books/:id` — update a book (librarian only).
  - `DELETE /api/v1/books/:id` — delete a book (librarian only).
  - `POST /api/v1/borrowings` — borrow a book (member only).
  - `PUT /api/v1/borrowings/:id/return` — mark a book as returned (librarian only).
  - `GET /api/v1/dashboard` — returns dashboard data based on user role.
  - All endpoints return appropriate HTTP status codes (200, 201, 204, 401, 403, 404, 422).
