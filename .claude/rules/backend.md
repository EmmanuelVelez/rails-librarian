---
paths:
  - "backend/**"
---

# Backend Conventions

## Controllers

- API controllers live under `app/controllers/api/v1/`; Devise controllers under `app/controllers/users/`.
- Every action must call `authorize` (Pundit) before accessing data.
- List endpoints use `pagy` for pagination and include a `pagination` key in the response.
- Always return the standard JSON envelope: `{ status: { code, message }, data: ... }`.

## Models

- `Book::GENRES` defines the allowed genre list; genre is validated with `inclusion`.
- `Borrowing` has scopes: `.active`, `.overdue`, `.due_today`.
- `available_copies` is derived (`total_copies - borrowings.active.count`), not a stored column.
- Books with active borrowings cannot be deleted.

## Authorization (Pundit)

- Policies: `BookPolicy`, `BorrowingPolicy`, `DashboardPolicy`.
- Only librarians can create/update/delete books and return borrowed books.
- Only members can borrow books.
- Dashboard is accessible to any authenticated user; response varies by role.

## Testing

- RSpec request specs in `spec/requests/`, model specs in `spec/models/`.
- Factories in `spec/factories/` using FactoryBot; assertions with Shoulda Matchers.
- `spec/support/auth_helpers.rb` provides `auth_headers_for(user)` to get JWT headers in tests.
- Run command: `docker compose exec -T -e RAILS_ENV=test web bundle exec rspec`
- The test database is `library_test`, separate from development `library_development`.

## Database

- PostgreSQL runs in Docker via `docker-compose.yml` in `backend/`.
- Never edit `db/schema.rb` manually; use migrations.
- Seed data in `db/seeds.rb` — re-run with `docker compose exec web rails db:seed`.
