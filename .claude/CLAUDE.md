# Library Management System

Full-stack library app: Ruby on Rails API backend + React TypeScript SPA frontend.

## Tech Stack

- **Backend**: Ruby 3.4 / Rails 8.1 (API-only), PostgreSQL 15, Devise + devise-jwt, Pundit, Pagy, RSpec
- **Frontend**: React 18, TypeScript, Vite 5, Tailwind CSS v4, shadcn/ui, React Router v7, TanStack Query v5, Axios

## Running the App

```bash
# Backend (Docker)
cd backend
docker compose up

# Seed data (after containers are running)
docker compose exec web rails db:seed

# Frontend
cd frontend
npm install
npm run dev
```

Backend runs on http://localhost:3000, frontend on http://localhost:5173.

## Running Tests

```bash
# Backend — RSpec (must pass RAILS_ENV=test)
cd backend
docker compose exec -T -e RAILS_ENV=test web bundle exec rspec

# Frontend — build check
cd frontend
npm run build
```

## Seed Credentials

| Role      | Email                    | Password    |
|-----------|--------------------------|-------------|
| Librarian | librarian@example.com    | password123 |
| Member    | member1@example.com      | password123 |
| Member    | member2@example.com      | password123 |

## Architecture

- API-only Rails; all resource routes under `/api/v1/*`, auth routes under `/auth/*`
- JWT token is returned in the `Authorization` response header (not in JSON body)
- Pundit policies enforce role-based access (librarian vs member)
- Pagy handles server-side pagination on all list endpoints
- Standard JSON envelope for every response:
  ```json
  { "status": { "code": 200, "message": "..." }, "data": ..., "pagination": ... }
  ```
- Two user roles: `member` (default) and `librarian` — set via enum on User model
- Book genres restricted to a predefined list in `Book::GENRES`
- Borrowing due date auto-set to 14 days from borrow date

## Environment Variables

| Variable              | Location       | Purpose                         |
|-----------------------|----------------|---------------------------------|
| DATABASE_URL          | backend/.env   | PostgreSQL connection string    |
| DEVISE_JWT_SECRET_KEY | backend/.env   | Secret for signing JWTs         |
| VITE_API_URL          | frontend/.env  | Backend URL (default localhost) |

## Key References

- @USER_STORIES.md — acceptance criteria for all features
- @README.md — full API docs, data models, authorization matrix
