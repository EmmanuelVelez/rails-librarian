---
paths:
  - "frontend/**"
---

# Frontend Conventions

## Stack

- React 18 + TypeScript, Vite 5, Tailwind CSS v4, shadcn/ui components.
- Routing: React Router v7. Server state: TanStack Query v5. HTTP: Axios.

## Project Structure

- `src/pages/` — page components (one per route).
- `src/components/ui/` — shadcn/ui primitives (Button, Card, Table, Dialog, etc.).
- `src/components/` — app-level shared components (StatsCard, Layout, etc.).
- `src/lib/*-api.ts` — API functions grouped by domain (auth, books, borrowings, dashboard).
- `src/lib/hooks/use-*.ts` — TanStack Query hooks wrapping the API functions.
- `src/lib/api-client.ts` — shared Axios instance with JWT interceptors.
- `src/contexts/AuthContext.tsx` — auth state, login/logout/register methods.
- `src/types/` — TypeScript interfaces for API data (Book, Borrowing, User, dashboard types).

## API Layer Pattern

1. Define async API functions in `src/lib/<domain>-api.ts` calling `apiClient`.
2. Wrap them in `useQuery` / `useMutation` hooks in `src/lib/hooks/use-<domain>.ts`.
3. Consume hooks in page components; invalidate related query keys on mutation success.

## Auth

- JWT stored in `localStorage` under `"token"`; user object under `"user"`.
- `api-client.ts` auto-attaches the token on every request and handles 401 -> redirect to `/login`.
- Token is received from the `Authorization` response header (not JSON body).

## Styling

- Tailwind utility classes only; no CSS modules or custom CSS files.
- Use shadcn/ui components as the design system base.
- Path alias `@/` maps to `src/` (configured in `tsconfig.app.json` and `vite.config.ts`).
