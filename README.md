# VetCommandCenter

VetCommandCenter is a Phoenix LiveView + PostgreSQL veterinary clinic command center.

## Current implementation status

This repository currently contains:

- Phoenix 1.8 application scaffold.
- Generated Phoenix LiveView authentication for `Accounts.User`.
- Local PostgreSQL development setup via Docker Compose.
- ULID helper/type foundation for time-sortable IDs.
- `Audit` context with append-only `audit_events` records, `metadata`, `actor_snapshot`, actor/location/entity fields, and query helpers.
- Tests for authentication, baseline web pages, ULID helpers, and audit logging/query behavior.

## Prerequisites

- Elixir and Erlang/OTP compatible with `mix.exs`.
- PostgreSQL 16+, either local or via Docker Compose.
- Node/npm tooling is managed by Phoenix asset tasks.

## Local database

The default dev/test database credentials are:

- username: `postgres`
- password: `postgres`
- host: `localhost`
- dev database: `vet_command_center_dev`
- test database: `vet_command_center_test`

Start PostgreSQL with Docker Compose:

```bash
docker compose up -d postgres
```

Stop it with:

```bash
docker compose down
```

Remove the local database volume if you need a clean database:

```bash
docker compose down -v
```

## Setup

Install dependencies, create/migrate/seed the database, and build assets:

```bash
mix setup
```

If dependencies are already installed and you only need database setup:

```bash
mix ecto.setup
```

Run pending migrations:

```bash
mix ecto.migrate
```

## Running the app

Start Phoenix:

```bash
mix phx.server
```

Or inside IEx:

```bash
iex -S mix phx.server
```

Visit <http://localhost:4000>.

Authentication routes are available at:

- `/users/register`
- `/users/log-in`
- `/users/settings`

In development, confirmation emails can be viewed at:

- `/dev/mailbox`

## Tests and checks

Run the full test suite:

```bash
mix test
```

Run the project precommit alias:

```bash
mix precommit
```

The current verified state passes `mix precommit`.

## Notes for Windows development

Phoenix LiveView may warn that it cannot create a symlink for colocated JS unless the terminal has symlink permissions. The app and tests still run. To remove the warning, either run the terminal once as Administrator or configure Windows Developer Mode/symlink permissions.
