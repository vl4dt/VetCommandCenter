# ADR 0001: Phoenix LiveView Stack

## Status

Accepted

## Context

VetCommandCenter v1 is a cloud SaaS, medical-records-first veterinary clinic system. The first implementation target is an end-to-end wellness/vaccine visit vertical slice for small independent dog/cat clinics.

The app needs:

- collaborative clinical workflows,
- a real-time today board,
- many structured forms,
- strong server-side authorization,
- Postgres-backed auditability,
- responsive desktop/tablet web UI,
- modular monolith architecture.

## Decision

Use **Phoenix LiveView + Elixir + Postgres** as the primary application stack.

The application will be LiveView-first, with internal JSON endpoints only where necessary.

Business logic must live in Phoenix contexts under `lib/app/`, not in LiveViews/controllers.

## Consequences

Positive:

- Excellent fit for real-time today board and workflow state changes.
- Server-rendered interactivity reduces frontend/backend split complexity.
- Ecto/Postgres fit the audit-heavy domain model.
- Phoenix contexts support modular-monolith boundaries.
- LiveView works well for form-heavy clinical CRUD workflows.

Tradeoffs:

- Requires Elixir/Phoenix familiarity.
- Rich text editing may need careful JavaScript hook integration.
- Some client-side interactions, uploads, and AI calls may require JS hooks or small JSON endpoints.

## Implementation Notes

Use Phoenix generators where practical:

- `mix phx.new`
- `mix phx.gen.auth`
- `mix phx.gen.live` or hand-written LiveViews after context design
- `mix test`

Keep the app structured around contexts such as:

- Accounts
- Orgs
- Staff
- Clients
- Patients
- Visits
- ClinicalRecords
- AiDrafting
- Documents
- Attachments
- Audit
