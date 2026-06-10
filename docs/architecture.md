# VetCommandCenter Architecture Notes

## Architecture Direction

VetCommandCenter v1 is a conventional cloud SaaS built as a modular monolith with Postgres as the source of truth.

The product is medical-records-first, with an end-to-end wellness/vaccine visit vertical slice as the first implementation target.

## Deployment

- Cloud SaaS in v1.
- Desktop/laptop web and tablet-responsive UI.
- No native mobile apps in v1.
- Design should not prevent limited offline mode later, but offline is not a v1 requirement.

## Application Shape

Use a modular monolith: one deployable application/API with clear internal module boundaries.

Suggested modules:

- Identity and access control.
- Organizations and clinic locations.
- Staff profiles.
- Households, contacts, and patients.
- Visits and today board.
- Vitals/observations.
- Clinical records and notes.
- Signed snapshots and amendments.
- AI drafting.
- Templates and catalog.
- Vaccines and reminders.
- Estimates and client-facing documents.
- Prescriptions.
- Attachments/storage.
- Audit log.
- Reporting.

Avoid microservices in v1.

## Tenant Model

### Canonical Tenant Boundary

- `organization_id` is the hard tenant boundary for security and queries.
- Tenant-owned tables should include `organization_id` directly rather than relying only on relationship traversal.
- `clinic_location_id` is used where location matters operationally.

Examples of location-scoped/operational records:

- Visits.
- Today board records/status.
- Staff assignments.
- Rooms.
- Future appointments.
- Some documents/reports.

### Organization and Location

- `organization` represents the tenant/legal clinic account.
- `clinic_location` belongs to organization.
- V1 UI is optimized for one location.
- The data model supports multiple locations later.

## Authorization Model

### App-Layer Authorization First

V1 uses application-layer authorization.

- Postgres row-level security is not required in v1.
- Schema should be designed so RLS can be added later.
- All tenant-owned tables carry `organization_id` to support future RLS and simple authorization predicates.
- Service/API authorization tests are critical.

### Authentication

Do not hand-roll auth primitives.

Use either:

- a managed auth provider, or
- a mature framework-native auth library,

depending on the final stack.

### User and Membership

- A user has a global identity.
- A user may belong to multiple organizations.
- Organization membership stores role/capabilities for that organization.
- Role is organization-wide in v1.
- Optional location access constraints can be added later.

V1 membership invitations:

- Pilot-ready flow uses email invitation links.
- Invite includes organization, role, expiration, and acceptance status.
- Earliest local/dev prototype may seed users manually.

### Roles

V1 roles are fixed but backed by named permission capabilities internally:

- Admin/owner.
- Practice manager.
- Veterinarian.
- Technician/nurse.
- Receptionist.

Do not build custom role/permission UI in v1.

### Non-Negotiable Medical Authority Rules

Only appropriately authorized veterinarians can:

- sign/finalize medical notes,
- approve prescriptions,
- approve AI-generated medical content before it becomes part of the signed record or leaves the clinic under clinical authority.

Signing authority should not rely only on a role label.

Use explicit authority/credential capability such as:

- `can_sign_medical_records`.

This should be checked alongside membership role/capabilities.

## Staff Profiles

Clinical/operational staff identity is separate from login identity.

- `staff_profile` belongs to organization.
- `staff_profile` may optionally link to `user_id`.
- Staff profiles can exist without user accounts.
- Visits assign staff profiles, not only user accounts.
- Former staff can remain referenced historically while inactive.

Suggested staff profile fields:

- organization_id,
- optional user_id,
- display name,
- staff type: veterinarian, technician/nurse, receptionist, manager, other,
- active/inactive,
- credential/signing capability flags,
- signature block/credential text later,
- license fields later if needed.

## Audit Log

### Scope

Audit log covers:

- clinical mutations,
- AI generations,
- note sign/amend events,
- prescription approvals,
- attachment changes,
- user/role/settings changes,
- template/catalog changes.

Do not audit every read/view in v1.

### Mutability

V1 audit logs are append-only at the application level:

- insert only,
- no application update/delete routes,
- not editable through admin UI.

Design should allow stronger DB enforcement later.

### Actor Model

Audit events should store:

- organization_id,
- clinic_location_id where relevant,
- actor_user_id,
- actor_staff_profile_id when available,
- actor display/name snapshot,
- event type,
- target entity type/id,
- timestamp,
- structured metadata/diff where appropriate.

Future fields may support system actors or impersonation.

## ID Strategy

Use ULIDs or another time-sortable globally unique ID format for domain records.

Reasons:

- public-URL-safe,
- globally unique,
- roughly chronological,
- friendlier for distributed creation later than sequential integers.

Use consistently unless final framework/database tooling strongly dictates otherwise.

## Deletion and Record Lifecycle

Clinical records should not disappear silently.

Use:

- void/cancel states for mistaken visits, notes, prescriptions, etc.,
- inactive/archive states for patients, templates, catalog items,
- soft delete for admin/config records where appropriate,
- hard delete only for narrow cases such as unsaved drafts or future legally required purge workflows.

Audit all destructive, void, archive, and restore actions.

## Household, Contact, and Patient Model

### Contacts and Households

Use org-scoped contacts linked to households via relationship table.

- `contact` belongs to organization.
- `household` belongs to organization.
- `household_contact` links contacts to households.

This supports:

- one household with multiple contacts,
- multiple pets in one household,
- co-owners,
- shared custody/foster/rescue relationships later,
- avoiding duplicate client contacts where practical.

Household contact relationship should support:

- primary contact flag,
- relationship label/role,
- authorization flags later,
- contact preferences later.

### Patients

Patient belongs to household.

Optional patient-contact relationship overrides can be added later for:

- primary responsible contact override,
- authorized decision makers,
- do-not-contact edge cases.

Patient lifecycle states:

- active,
- inactive,
- deceased.

### Dog/Cat Patient Demographics

V1 patient demographics:

- name,
- species,
- breed,
- sex,
- spay/neuter status,
- date of birth or estimated age,
- color/markings,
- microchip,
- optional photo,
- cached latest weight if useful.

Insurance is deferred.

### Breed

Use a reference table with:

- species,
- breed name,
- active flag,
- Mixed,
- Unknown,
- Other.

Allow optional free-text display override for Other or mixed cases.

Avoid complex multi-breed modeling in v1.

## Patient History

Minimum patient chart includes:

- chronological visit timeline,
- structured problem list,
- allergies/adverse reactions,
- current/recent medications,
- vaccines/reminders,
- attachments.

Problem list uses structured entries without coding:

- name,
- status: active/resolved/inactive,
- onset/date noted,
- notes,
- linked visits.

AI may suggest changes to the problem list but must not silently modify it.

## Vitals and Observations

Vitals are longitudinal clinical observations, not just fields on a note.

Use a separate observation/vitals table linked to:

- organization,
- patient,
- visit usually,
- entering staff/user,
- captured timestamp.

Suggested fields:

- weight,
- temperature,
- heart rate,
- respiratory rate,
- pain score,
- body condition score,
- units/display metadata,
- normalized canonical values.

Clinic-level unit preferences control display.

For US launch, defaults may be lb and °F, while storing normalized canonical values where practical.

Patient may cache latest weight for fast display.

## Visit and Today Board

V1 includes simple clinical visit tracking/today board, not a full scheduling calendar.

### Visit Location and Staff

Visit belongs to:

- organization,
- clinic_location,
- patient,
- household context if useful,
- assigned veterinarian staff profile,
- assigned technician/nurse staff profile,
- room optional.

### Visit Type

Use a fixed v1 enum connected to templates but distinct from selected template.

Initial types:

- wellness,
- vaccine,
- wellness_vaccine,
- sick,
- recheck,
- procedure/consult later,
- euthanasia later,
- other.

### Visit Status

Fixed v1 statuses should support today-board workflow:

- created/scheduled,
- checked_in,
- intake_in_progress,
- ready_for_vet,
- in_exam,
- ready_for_discharge,
- checked_out,
- note_signed/complete,
- cancelled/voided.

Avoid custom workflow statuses in v1.

### Readiness and Blockers

Use both derived blockers and manually dismissible/overrideable blockers.

Derived examples:

- vitals missing,
- intake incomplete,
- no note draft,
- estimate pending,
- discharge not approved,
- note unsigned.

Manual override examples:

- vitals impossible/aggressive patient,
- estimate declined/not needed,
- discharge instructions not needed.

Overrides should store:

- reason,
- actor,
- timestamp,
- blocker type.

## Clinical Notes

### Note Model

V1 uses SOAP core with optional templates/checklists.

Notes combine:

- structured clinical fields,
- editable narrative rich text.

Use typed note sections rather than one large blob.

Example `note_section` fields:

- note_id,
- section_type: subjective, objective, assessment, plan, discharge, internal, etc.,
- structured rich-text document content,
- generated_by_ai flag,
- optional source_ai_generation_id,
- display order,
- timestamps.

### Rich Text Format

Use a structured rich-text document format such as ProseMirror/Tiptap JSON.

Benefits:

- editor-friendly,
- controlled formatting,
- safer rendering,
- better future diffing,
- better PDF/export path.

### Note Statuses

- Draft.
- Ready for vet review.
- Signed/finalized.
- Amended.
- Voided/cancelled if needed.

### Signing

A note becomes final only when a veterinarian with explicit signing authority signs it.

On signing, create an immutable signed snapshot containing:

- structured rich-text JSON,
- canonical rendered HTML/text,
- structured clinical field snapshot,
- signer user ID,
- signer staff profile ID,
- signer display/credential snapshot,
- timestamp.

Do not rely on mutable note rows as the legal record.

### Amendments

V1 amendments are appended records linked to the immutable signed snapshot.

Amendment should include:

- author/signing vet,
- timestamp,
- reason,
- content,
- rendered content if needed.

Do not unlock and silently edit signed notes.

No co-signing/supervising workflow in v1.

## AI Drafting

### Service Boundary

Use an `AiDraftingService` interface.

- Mock provider by default for deterministic demos/tests.
- Optional real provider adapter behind configuration.
- Do not couple domain logic to one AI vendor.

### AI Generation Records

Store AI generations in audit/domain records with:

- organization_id,
- visit_id/note_id/section_id where relevant,
- source input references/IDs,
- prompt template/version,
- provider/model/version,
- generated output,
- actor,
- timestamp,
- accepted/rejected/regenerated status,
- token counts,
- estimated cost,
- latency,
- safety flags,
- missing-information flags.

Avoid retaining provider-specific raw full request/response blobs indefinitely unless there is a protected, deliberate retention policy.

### Multiple Generations

Keep all AI generations in audit/history.

The visible note section points to the accepted/current content. Earlier unaccepted generations need not clutter the main UI.

### Safety Boundary

AI may draft and summarize. It must not:

- diagnose autonomously,
- prescribe autonomously,
- recommend treatment autonomously,
- finalize medical records,
- send client messages,
- invent missing facts,
- silently modify problem lists, reminders, prescriptions, or signed records.

## Client-Facing Documents

Client-facing documents have their own approval lifecycle:

- draft,
- approved,
- exported/printed.

Examples:

- discharge instructions,
- visit summary,
- generic vaccine summary,
- estimate/consent printout.

Medical instructions require veterinarian approval.

V1 document output should use print-friendly HTML pages first. Server-side PDF generation can be added later.

## Attachments

Store files in object storage with database metadata.

Do not store file blobs in Postgres.

Use separate file metadata and link tables:

- `attachment_file`: uploaded object metadata,
- `attachment_link`: links files to patient, visit, note, estimate, consent, etc.

Suggested file metadata:

- organization_id,
- storage key,
- file name,
- MIME type,
- file size,
- checksum,
- uploaded_by,
- created_at,
- category,
- security/access metadata.

A file may be linked to multiple records.

## Vaccines and Reminders

### Vaccines

Use dedicated vaccine administration records backed by catalog items.

Suggested fields:

- organization_id,
- patient_id,
- visit_id,
- catalog_item_id optional,
- vaccine name snapshot,
- manufacturer optional,
- lot number optional,
- expiry optional,
- administered date,
- administered by staff profile,
- route/site optional,
- next due date,
- linked reminder_id optional.

Do not build immunization registry integration in v1.

### Reminders

Use clinic-editable reminder rules attached to catalog/template items, seeded with defaults.

- Vaccine catalog items can have default reminder intervals.
- Wellness templates can create recommended reminders.
- Staff/vet can edit due dates before saving.
- AI does not decide due dates autonomously.

## Estimates

V1 estimates are lightweight treatment-plan/estimate documents, not invoices.

Use both:

- catalog-backed line items,
- ad hoc free-text line items.

Suggested line fields:

- description,
- quantity,
- unit price,
- optional catalog item,
- grouping: required/recommended/optional.

V1 supports required/recommended/optional grouping and whole-document approval/attached signed copy.

No line-level client acceptance tracking in v1.

## Prescriptions

Prescriptions are structured records separate from plan text.

They link to:

- organization,
- patient,
- visit,
- note/plan section if useful,
- prescribing veterinarian staff profile,
- medication catalog item optional.

Lifecycle:

- draft,
- approved,
- printed/exported,
- voided.

Only veterinarians with authority can approve prescriptions.

No full dispensing/refill/inventory lifecycle in v1.

## Templates and Catalog

V1 supports:

- system default templates,
- clinic-level editable templates,
- medication/procedure catalog,
- vaccine catalog items,
- estimate/catalog line defaults,
- common medication instructions,
- discharge instruction snippets.

No marketplace, per-user templates, custom workflow builder, or custom permission builder in v1.

## Reporting

V1 operational reporting should derive from the above model:

- unsigned notes,
- notes signed same day,
- median time to sign,
- visits by status,
- readiness blockers,
- reminders due,
- AI usage/acceptance,
- missing-field flags.

No business/revenue dashboards until billing data exists.

## Open Implementation Decisions

Still to decide:

- Final frontend/backend stack.
- Auth provider/library.
- ORM/query layer.
- Object storage provider.
- Rich text editor library.
- Print-friendly document rendering approach.
- Real AI provider adapter and prompt/versioning strategy.
- Exact schema migrations.
- API style: REST, RPC, GraphQL, or framework server actions.
