# Library Management System

Full-stack application with a Ruby on Rails API backend and a React SPA frontend.

## Tech Stack

### Backend
- Ruby 3.4.2 / Rails 8.1.3 (API-only)
- PostgreSQL 15
- Devise + devise-jwt (JWT authentication)
- Pundit (authorization)
- Rack::Attack (rate limiting)
- Pagy (pagination)
- RSpec, FactoryBot, Shoulda Matchers (testing)
- Docker + Docker Compose

### Frontend
- React 18 + TypeScript
- Vite 5
- Tailwind CSS v4
- shadcn/ui
- React Router v7
- TanStack Query v5
- Axios

## Prerequisites

- Docker & Docker Compose
- Node.js >= 20 (recommend using `nvm use 22`)
- npm

## Getting Started

### Backend

```bash
cd backend
docker compose up
```

This will:
1. Pull and start the PostgreSQL container
2. Build the Rails image and install gems
3. Run `db:prepare` (create + migrate the database)
4. Start the Rails server on **http://localhost:3000**

### Seed Data

After the containers are running, load the seed data:

```bash
cd backend
docker compose run --rm web rails db:seed
```

This creates:
- **Librarian**: `librarian@example.com` / `password123`
- **Member 1**: `member1@example.com` / `password123`
- **Member 2**: `member2@example.com` / `password123`
- 10 books across different genres
- Sample borrowings (active, overdue, due today, and returned)

### Frontend

```bash
cd frontend
npm install
npm run dev
```

The frontend dev server starts on **http://localhost:5173**.

## API Endpoints

All endpoints are namespaced under `/auth` (authentication) and `/api/v1` (resources). All resource endpoints require the `Authorization: Bearer <token>` header.

### Authentication

| Method | Path            | Description                      | Access  |
|--------|-----------------|----------------------------------|---------|
| POST   | /auth/register  | Register a new user (returns JWT)| Public  |
| POST   | /auth/login     | Login (returns JWT)              | Public  |
| DELETE | /auth/logout    | Logout (revokes JWT)             | Auth    |

All `/auth/*` endpoints are rate-limited (see [Rate Limiting](#rate-limiting) below).

### Books

| Method | Path              | Description                        | Access    |
|--------|-------------------|------------------------------------|-----------|
| GET    | /api/v1/books     | List all books (paginated, supports `?q=` search) | Any user  |
| GET    | /api/v1/books/:id | Show a single book                 | Any user  |
| POST   | /api/v1/books     | Create a book                      | Librarian |
| PATCH  | /api/v1/books/:id | Update a book                      | Librarian |
| DELETE | /api/v1/books/:id | Delete a book                      | Librarian |

### Borrowings

| Method | Path                              | Description                        | Access    |
|--------|-----------------------------------|------------------------------------|-----------|
| GET    | /api/v1/borrowings                | List borrowings (paginated, scoped by role) | Any user  |
| POST   | /api/v1/borrowings                | Borrow a book                      | Member    |
| PUT    | /api/v1/borrowings/:id/return     | Return a book (sets `returned_at`) | Librarian |

Members see only their own borrowings; librarians see all.

### Dashboard

| Method | Path              | Description                              | Access   |
|--------|-------------------|------------------------------------------|----------|
| GET    | /api/v1/dashboard | Returns dashboard data based on user role | Any user |

- **Librarian**: total books, total borrowings, active borrowings, overdue count, due today, books available, and a list of members with overdue books (member name, book title, due date).
- **Member**: active borrowings with due dates, overdue borrowings, and borrowing history count.

The JWT token is returned in the `Authorization` response header on login and registration, and must be sent back in the same header on subsequent requests.

## Rate Limiting

All `/auth/*` endpoints are protected by Rack::Attack throttling to prevent brute-force and abuse:

| Rule               | Scope              | Limit               |
|--------------------|--------------------|----------------------|
| Login throttle     | `POST /auth/login` | 5 requests / 20s per IP  |
| Register throttle  | `POST /auth/register` | 3 requests / 60s per IP |
| Auth catch-all     | All `/auth/*`      | 20 requests / 60s per IP |

When a limit is exceeded the API returns a `429 Too Many Requests` response:

```json
{
  "status": { "code": 429, "message": "Too many requests. Please try again later." }
}
```

## Pagination

All index/list endpoints (`GET /api/v1/books`, `GET /api/v1/borrowings`) support server-side pagination via query parameters:

| Parameter | Default | Max | Description          |
|-----------|---------|-----|----------------------|
| `page`    | 1       | --  | Page number          |
| `per_page`| 10      | 50  | Results per page     |

Example request:

```bash
curl "http://localhost:3000/api/v1/books?page=2&per_page=5" \
  -H "Authorization: Bearer <token>"
```

Paginated responses include a `pagination` object alongside the `data` array:

```json
{
  "status": { "code": 200, "message": "Books retrieved successfully." },
  "data": [ ... ],
  "pagination": {
    "page": 2,
    "per_page": 5,
    "total_pages": 4,
    "total_count": 18,
    "next_page": 3,
    "prev_page": 1
  }
}
```

The dashboard endpoint (`GET /api/v1/dashboard`) is not paginated as it returns aggregate statistics.

## API Usage Examples

### Register

```bash
curl -X POST http://localhost:3000/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "first_name": "Jane",
      "last_name": "Doe",
      "email": "jane@example.com",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

### Login

```bash
curl -i -X POST http://localhost:3000/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "librarian@example.com",
      "password": "password123"
    }
  }'
```

The `-i` flag shows response headers so you can grab the `Authorization: Bearer <token>` value.

### Create a Book (librarian)

```bash
curl -X POST http://localhost:3000/api/v1/books \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "book": {
      "title": "Pragmatic Programmer",
      "author": "David Thomas",
      "genre": "Technology",
      "isbn": "978-0135957059",
      "total_copies": 3
    }
  }'
```

Genre must be one of: Fiction, Dystopian, Science, Philosophy, Science Fiction, History, Technology, Fantasy, Biography.

### Borrow a Book (member)

```bash
curl -X POST http://localhost:3000/api/v1/borrowings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "borrowing": {
      "book_id": 1
    }
  }'
```

### Return a Book (librarian)

```bash
curl -X PUT http://localhost:3000/api/v1/borrowings/1/return \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>"
```

### Search Books

```bash
curl "http://localhost:3000/api/v1/books?q=fiction&page=1&per_page=10" \
  -H "Authorization: Bearer <token>"
```

## Running Tests

### Backend (RSpec)

```bash
cd backend
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec
```

### Frontend (build check)

```bash
cd frontend
npm run build
```

## Data Models

### User

| Field      | Type    | Notes                              |
|------------|---------|------------------------------------|
| first_name | string  | required                           |
| last_name  | string  | required                           |
| email      | string  | required, unique                   |
| password   | string  | required, min 6 chars (Devise)     |
| role       | enum    | `member` (default) or `librarian`  |

### Book

| Field        | Type    | Notes                                                                                              |
|--------------|---------|----------------------------------------------------------------------------------------------------|
| title        | string  | required                                                                                           |
| author       | string  | required                                                                                           |
| genre        | string  | required, must be one of: Fiction, Dystopian, Science, Philosophy, Science Fiction, History, Technology, Fantasy, Biography |
| isbn         | string  | required, unique                                                                                   |
| total_copies | integer | required, >= 0, default 1                                                                          |

### Borrowing

| Field       | Type     | Notes                                      |
|-------------|----------|--------------------------------------------|
| user_id     | FK       | belongs_to User                            |
| book_id     | FK       | belongs_to Book                            |
| borrowed_at | datetime | required, set on creation                  |
| due_date    | date     | required, auto-set to 14 days from borrow  |
| returned_at | datetime | null until returned                        |

**Validations**: no duplicate active borrowings per user+book, available copies check on borrow, books with active borrowings cannot be deleted.

**Scopes**: `Borrowing.active`, `Borrowing.overdue`, `Borrowing.due_today`.

## Authorization Rules

| Action              | Member | Librarian |
|---------------------|--------|-----------|
| View books          | Yes    | Yes       |
| Search books        | Yes    | Yes       |
| Create/edit/delete books | No | Yes      |
| Borrow a book       | Yes    | No        |
| Return a book       | No     | Yes       |
| View own borrowings | Yes    | Yes (all) |
| Dashboard           | Yes (own data) | Yes (library-wide stats) |

## Project Structure

```
.
├── .claude/                        # Claude Code project config
│   ├── CLAUDE.md                   # Project overview (loaded every session)
│   ├── rules/                      # Path-scoped convention files
│   │   ├── backend.md
│   │   └── frontend.md
│   └── settings.local.json         # Tool permissions
├── backend/
│   ├── app/
│   │   ├── controllers/
│   │   │   ├── users/              # Devise JWT controllers (sessions, registrations)
│   │   │   └── api/v1/             # Namespaced API controllers
│   │   │       ├── books_controller.rb
│   │   │       ├── borrowings_controller.rb
│   │   │       └── dashboard_controller.rb
│   │   ├── models/                 # User, Book, Borrowing, JwtDenylist
│   │   ├── policies/              # Pundit policies (Book, Borrowing, Dashboard)
│   │   └── serializers/           # Book, Borrowing, User serializers
│   ├── config/
│   │   ├── initializers/devise.rb  # JWT dispatch/revocation config
│   │   └── routes.rb               # /auth/* and /api/v1/* routes
│   ├── db/
│   │   ├── migrate/               # Schema migrations
│   │   └── seeds.rb               # Seed data
│   ├── spec/
│   │   ├── requests/              # Endpoint specs (auth, books, borrowings, dashboard)
│   │   ├── models/                # Model specs (user, book, borrowing)
│   │   ├── factories/             # FactoryBot definitions
│   │   └── support/               # Auth helpers (auth_headers_for)
│   ├── docker-compose.yml
│   ├── Dockerfile
│   └── .env                       # DB + JWT secret (not committed)
├── frontend/
│   ├── src/
│   │   ├── components/ui/         # shadcn/ui components
│   │   ├── contexts/              # AuthContext (auth state + localStorage)
│   │   ├── lib/
│   │   │   ├── api-client.ts      # Shared Axios instance (JWT interceptors)
│   │   │   ├── *-api.ts           # Domain API functions (auth, books, borrowings, dashboard)
│   │   │   └── hooks/             # TanStack Query hooks (use-books, use-borrowings, use-dashboard)
│   │   ├── pages/                 # Login, Register, Dashboard, Books, BookDetail, BookForm
│   │   └── types/                 # TypeScript interfaces (Book, Borrowing, User, dashboard)
│   └── .env                       # VITE_API_URL
├── USER_STORIES.md                 # Acceptance criteria for all features
└── README.md
```

## Environment Variables

### Backend (`backend/.env`)

| Variable               | Description                    |
|------------------------|--------------------------------|
| POSTGRES_USER          | PostgreSQL username            |
| POSTGRES_PASSWORD      | PostgreSQL password            |
| POSTGRES_DB            | PostgreSQL database name       |
| DATABASE_URL           | Full PostgreSQL connection URL |
| DEVISE_JWT_SECRET_KEY  | Secret for signing JWTs        |

### Frontend (`frontend/.env`)

| Variable      | Description                          |
|---------------|--------------------------------------|
| VITE_API_URL  | Backend URL (default: http://localhost:3000) |
