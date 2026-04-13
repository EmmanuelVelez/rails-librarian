# Generative AI Tools — Task Management API

## Context: Base Project

For this exercise I used my **Library Management System** (a Rails 8 API-only application) as the base project. The library system already had a fully working backend with the following infrastructure in place:

- **Devise + devise-jwt** for authentication — JWT tokens issued on login/register, revoked on logout via a `JwtDenylist` database table, and required on every API request through `before_action :authenticate_user!`.
- **Pundit** for authorization — policy objects that enforce role-based access control (e.g., librarians vs. members), including `policy_scope` for row-level data scoping.
- **Pagy** for pagination — all list endpoints return paginated results with metadata (`page`, `per_page`, `total_pages`, `total_count`, `next_page`, `prev_page`), and `per_page` is clamped between 1 and 50 to prevent abuse.
- **Rack::Attack** for rate limiting — throttles on authentication endpoints to prevent brute-force attacks (5 login attempts per 20s, 3 registrations per 60s per IP).
- **RSpec + FactoryBot + Shoulda Matchers** for testing — comprehensive model specs and request specs covering happy paths, authorization, validation errors, and edge cases.

Having this existing infrastructure meant the prompt and the AI output could focus specifically on the **Task resource** (model, controller, policy, serializer, routes, and specs) rather than rebuilding auth, pagination, or authorization from scratch. The patterns established in the library project (consistent JSON envelope, plain Ruby serializers, Pundit policies, Pagy integration) carried directly into the task management API.

---

## 1. Prompt Refinement

I started with a rough, informal prompt and used Claude to refine it into a more precise and comprehensive version before feeding it into Cursor.

**My initial (manual) prompt:**

> Refine this prompt:
> Build RESTful API for a task resource
> task model attributes title, description, status, and due_date
> Tasks are associated with a user
> create the policy to restrict only for authenticated users
> prefix of the api is /api/v1/tasks
> Assume Auth is done with devise and JWT
> Generate RSpec specs

**Refined prompt (output from Claude, used in Cursor):**

> Generate a RESTful API for a task management system using Ruby on Rails 8 (API-only mode) with PostgreSQL. Requirements:
>
> - **Task model** with: `title` (string, required), `description` (text, optional), `status` (enum: pending, in_progress, completed; default pending), `due_date` (date, optional). Each task `belongs_to :user`.
> - **User model** already exists via Devise + devise-jwt with JWT authentication. Users have `email`, `first_name`, `last_name`, and a `role` enum (member, admin).
> - Full CRUD endpoints under `/api/v1/tasks` — index (paginated, filterable by status), show, create, update, destroy.
> - Only authenticated users can access endpoints. Members can only manage their own tasks; admins can see all tasks.
> - Use Pundit for authorization, Pagy for pagination, and plain Ruby serializer objects (no ActiveModel::Serializer gem).
> - Include model validations, proper HTTP status codes (200, 201, 401, 403, 404, 422), and consistent JSON envelope: `{ status: { code, message }, data, pagination }`.
> - Generate RSpec request specs and model specs with FactoryBot.

The refinement step added specificity around enum values, pagination strategy, serializer pattern, the JSON response envelope, and HTTP status code expectations — all of which led to significantly better initial output from the AI.

---

---

## 2. Output Code (Representative Sample)

### Migration

```ruby
class CreateTasks < ActiveRecord::Migration[8.1]
  def change
    create_table :tasks do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.integer :status, default: 0, null: false
      t.date :due_date

      t.timestamps
    end

    add_index :tasks, :status
    add_index :tasks, :due_date
  end
end
```

### Model — `app/models/task.rb`

```ruby
class Task < ApplicationRecord
  belongs_to :user

  enum :status, { pending: 0, in_progress: 1, completed: 2 }

  validates :title, presence: true
  validates :status, presence: true
  validate :due_date_not_in_past, on: :create

  scope :overdue, -> { where(status: [:pending, :in_progress]).where("due_date < ?", Date.current) }

  private

  def due_date_not_in_past
    return unless due_date.present?

    if due_date < Date.current
      errors.add(:due_date, "can't be in the past")
    end
  end
end
```

### Controller — `app/controllers/api/v1/tasks_controller.rb`

```ruby
module Api
  module V1
    class TasksController < ApplicationController
      before_action :authenticate_user!
      before_action :set_task, only: [:show, :update, :destroy]

      def index
        authorize Task
        scope = policy_scope(Task)
        scope = scope.where(status: params[:status]) if params[:status].present?
        pagy, tasks = pagy(scope, limit: per_page_param)

        render json: {
          status: { code: 200, message: "Tasks retrieved successfully." },
          data: tasks.map { |task| TaskSerializer.new(task).serializable_hash },
          pagination: pagination_meta(pagy)
        }, status: :ok
      end

      def show
        authorize @task
        render json: {
          status: { code: 200, message: "Task retrieved successfully." },
          data: TaskSerializer.new(@task).serializable_hash
        }, status: :ok
      end

      def create
        authorize Task
        task = current_user.tasks.new(task_params)

        if task.save
          render json: {
            status: { code: 201, message: "Task created successfully." },
            data: TaskSerializer.new(task).serializable_hash
          }, status: :created
        else
          render json: {
            status: { code: 422, message: "Task could not be created. #{task.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      def update
        authorize @task

        if @task.update(task_params)
          render json: {
            status: { code: 200, message: "Task updated successfully." },
            data: TaskSerializer.new(@task).serializable_hash
          }, status: :ok
        else
          render json: {
            status: { code: 422, message: "Task could not be updated. #{@task.errors.full_messages.to_sentence}" }
          }, status: :unprocessable_entity
        end
      end

      def destroy
        authorize @task
        @task.destroy
        render json: {
          status: { code: 200, message: "Task deleted successfully." }
        }, status: :ok
      end

      private

      def set_task
        @task = Task.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          status: { code: 404, message: "Task not found." }
        }, status: :not_found
      end

      def task_params
        params.require(:task).permit(:title, :description, :status, :due_date)
      end

      def per_page_param
        (params[:per_page] || 10).to_i.clamp(1, 50)
      end
    end
  end
end
```

### Policy — `app/policies/task_policy.rb`

```ruby
class TaskPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    user.admin? || record.user_id == user.id
  end

  def create?
    true
  end

  def update?
    user.admin? || record.user_id == user.id
  end

  def destroy?
    user.admin? || record.user_id == user.id
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end
end
```

### Serializer — `app/serializers/task_serializer.rb`

```ruby
class TaskSerializer
  def initialize(task)
    @task = task
  end

  def serializable_hash
    {
      id: @task.id,
      title: @task.title,
      description: @task.description,
      status: @task.status,
      due_date: @task.due_date,
      overdue: @task.due_date.present? && @task.due_date < Date.current && !@task.completed?,
      user_id: @task.user_id,
      created_at: @task.created_at,
      updated_at: @task.updated_at
    }
  end
end
```

### Routes (addition to `config/routes.rb`)

```ruby
namespace :api do
  namespace :v1 do
    resources :tasks, only: [:index, :show, :create, :update, :destroy]
  end
end
```

---

## 3. Validating the AI's Suggestions

I validated the AI output in several ways:

- **Ran the test suite.** I had the AI generate RSpec request specs and model specs (using FactoryBot and Shoulda Matchers), then ran `bundle exec rspec` to verify all endpoints return correct status codes and response shapes. My project has comprehensive request specs covering happy paths, authorization failures (403), validation errors (422), unauthenticated access (401), and not-found cases (404).
- **Manually tested with curl.** I hit every endpoint with valid and invalid payloads to confirm the JSON envelope structure (`status.code`, `status.message`, `data`, `pagination`) was consistent.
- **Reviewed authorization logic.** I verified that Pundit policies correctly scope records — members only see/edit their own tasks, admins see everything. I checked this both in specs and by logging in as different roles.
- **Checked database constraints.** I verified the migration had proper `null: false` constraints, foreign keys, and indexes for commonly queried columns (`status`, `due_date`, `user_id`).

---

## 4. Corrections and Improvements Made

Several corrections and improvements were necessary:

- **The AI initially used `ActiveModel::Serializer` gem.** I replaced it with plain Ruby serializer classes (like `TaskSerializer` above) — lighter weight, no extra dependency, and gives full control over the JSON shape. This matches the idiomatic pattern for Rails API-only apps.
- **Pagination was missing initially.** The AI returned all records in `index`. I integrated Pagy with a `per_page_param` method that clamps values between 1 and 50 to prevent abuse, and added `pagination_meta` to every list response.
- **The AI didn't include `policy_scope`.** The initial `index` action used `Task.all`, meaning members could see everyone's tasks. I added `policy_scope(Task)` to ensure row-level scoping.
- **Status filtering wasn't included.** I added `scope = scope.where(status: params[:status]) if params[:status].present?` so clients can filter by `?status=pending`.
- **The AI used string-based status instead of an integer-backed enum.** I corrected it to use `enum :status, { pending: 0, in_progress: 1, completed: 2 }` which is more performant (indexed integer column) and idiomatic in Rails.
- **Error responses were inconsistent.** The AI returned bare `{ error: "..." }` strings on some failures. I standardized every response to use the `{ status: { code, message }, data }` envelope, including the Pundit `NotAuthorizedError` rescue in `ApplicationController`.

---

## 5. Edge Cases, Authentication, and Validations

### Authentication

- JWT-based authentication via Devise + devise-jwt. Tokens are issued on login/register and revoked on logout using a `JwtDenylist` table (database-backed revocation strategy).
- Every API endpoint is protected with `before_action :authenticate_user!`. Unauthenticated requests receive a `401 Unauthorized`.
- Rate limiting via Rack::Attack prevents brute-force on auth endpoints (5 login attempts per 20s, 3 registrations per 60s per IP).

### Authorization

- Pundit policies enforce role-based access. Members can only CRUD their own tasks; admins can manage all tasks.
- `policy_scope` in the index action ensures database queries are scoped per user, not just filtered in Ruby — preventing data leaks.
- Unauthorized actions return a consistent `403 Forbidden` JSON response.

### Validations & Edge Cases

- `title` is required; `status` defaults to `pending` at the database level.
- `due_date` is validated to not be in the past on creation.
- The `status` enum rejects invalid values at the Rails level (raises `ArgumentError` for unknown values).
- `RecordNotFound` is rescued in `set_task` to return a clean `404` instead of a Rails exception.
- The serializer computes an `overdue` boolean flag (due_date passed and status is not completed) so the client doesn't have to calculate this.
- `per_page` is clamped to `1..50` to prevent clients from requesting unbounded result sets.

---

## 6. Performance and Idiomatic Quality Assessment

### Performance

- Used integer-backed enums with database indexes on `status` and `due_date` for efficient filtering and scoping.
- Pagination via Pagy (the fastest Ruby pagination gem, benchmarked at 40x faster than Kaminari/WillPaginate) prevents loading all records into memory.
- `includes(:user)` in list queries to avoid N+1 queries when serializing associated data.
- Foreign keys at the database level ensure referential integrity without application-layer overhead.

### Idiomatic Quality

- Follows Rails conventions: RESTful resource routing, strong parameters, `before_action` callbacks, model-level validations.
- API-only mode (`config.api_only = true`) strips unnecessary middleware (sessions, cookies, flash, views).
- Separation of concerns: models handle validation/business logic, policies handle authorization, serializers handle presentation, controllers orchestrate.
- Consistent JSON envelope across all endpoints makes the API predictable for frontend consumers.
- RSpec request specs test the full stack (routing → controller → model → database) rather than unit-testing controllers in isolation, which is the modern Rails testing convention.
- No unnecessary gems — plain Ruby serializers instead of heavy serialization libraries, Pundit instead of CanCanCan (lighter, policy-object pattern).

---

## Note on This Document

This document was itself assembled and formatted using **Cursor** (AI-assisted IDE). I provided the raw content, code samples, and key points, then used Cursor to structure it into a well-organized markdown document with consistent formatting, clear section headings, and properly highlighted code blocks. This is another example of how GenAI tools can accelerate not just code generation, but also technical writing and documentation.
