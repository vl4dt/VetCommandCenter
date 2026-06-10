# VetCommandCenter MVP Scope

## Product Thesis

VetCommandCenter is a modern, medical-records-first veterinary clinic system for small independent dog/cat clinics. Its core promise is to help clinics finish accurate medical records faster by combining collaborative clinical workflow, structured records, and useful AI-assisted documentation/admin drafting.

This is not an “AI veterinarian,” not a chatbot-first product, and not a full practice-management-system replacement in v1.

## Target Customer

- Primary buyer/user: small independent veterinary clinic.
- Initial clinical domain: companion animal clinics treating dogs and cats.
- Launch jurisdiction: United States, generic multi-state.
- V1 avoids state-specific legal claims/forms.

## Core Differentiator

Integrated medical record + useful AI + clinical readiness workflow:

- Staff intake, vitals, templates, SOAP notes, estimates, discharge instructions, reminders, and review/signoff live in one clinical workflow.
- AI removes documentation/admin burden only where it adds value.
- Veterinarians remain the clinical authority.

## MVP Success Metric

Primary metric:

- Reduction in time from visit start/end to signed medical record.

Secondary metrics:

- Percentage of notes signed same day.
- Median time to signed note.
- AI draft acceptance/edit rate.
- Missing-field flags resolved.
- Discharge documents generated.
- Staff-reported documentation burden.

## V1 Product Scope

### System Type

V1 is a medical-records-first system. It includes enough clinic primitives to stand alone for early pilot clinics, but does not attempt to be a full PMS.

The system is the source of truth for:

- Organizations/clinic locations.
- Households/accounts.
- Clients/contacts.
- Patients.
- Visits.
- Medical notes.
- Attachments.
- Prescriptions.
- Reminders.
- Templates/catalog items.

### Deployment and Devices

- Cloud SaaS for v1.
- Designed so limited offline mode can be added later.
- Must work well on desktop/laptop web and tablet-responsive layouts.
- No native mobile apps in v1.

## First Vertical Slice

The first working prototype should implement an end-to-end wellness/vaccine visit:

1. Create/select household.
2. Create/select patient.
3. Start visit from today board.
4. Select wellness template.
5. Staff enters intake/history, vitals, and checklist data.
6. AI drafts SOAP note and discharge/client summary from structured inputs.
7. Staff/vet creates lightweight estimate if needed.
8. System creates vaccine/preventive reminders.
9. Vet reviews, edits, approves prescriptions/medical content, and signs note.
10. Signed note snapshot is stored with audit trail.

## Clinical Record Model

### Patient Identity

- Household/account model.
- Household can contain multiple contacts and multiple pets.
- One primary contact.
- Patient lifecycle states: active, inactive, deceased.

### Patient History

Minimum useful chart:

- Chronological visit timeline.
- Structured problem list.
- Allergies/adverse reactions.
- Current/recent medications.
- Vaccines/reminders.
- Attachments.

Problem list:

- Structured entries without coding.
- Fields should include name, status, onset/date noted, notes, linked visits.
- AI may suggest problem-list changes but never silently modifies it.

### Notes

V1 note model:

- SOAP core.
- Optional visit templates/checklists.
- Structured clinical core plus editable narrative text.

Note statuses:

- Draft.
- Ready for vet review.
- Signed/finalized.
- Amended.

Finalization:

- Medical note becomes final only when veterinarian explicitly signs/finalizes.
- After signing, changes are amendments, not silent edits.
- Signed notes are stored as immutable signed snapshots of SOAP text, structured fields, signer, and timestamp.

## Wellness/Vaccine Workflow

V1 wellness/vaccine visit should support:

- Reason for visit.
- Staff-only structured intake.
- History.
- Weight/vitals.
- Physical exam checklist.
- Vaccines administered.
- Preventatives discussed/administered.
- Reminder creation.
- Optional lightweight estimate/treatment plan.
- Generic printable vaccine summary.
- Client-facing visit summary/discharge instructions.
- Consent/estimate documents generated for printing/signing externally.
- Signed scans/photos attachable to visit/patient record.

Rabies certificate support is deferred unless a specific launch jurisdiction is chosen.

## Today Board

V1 includes a simple visit list/today board, not a full appointment calendar.

It should track:

- Visit status.
- Assigned veterinarian.
- Assigned technician/nurse.
- Room.
- Clinical readiness/blockers:
  - intake incomplete,
  - vitals missing,
  - history incomplete,
  - AI note draft ready,
  - estimate pending,
  - discharge instructions pending approval,
  - note unsigned.

Avoid fully custom workflows in v1.

## Roles and Permissions

V1 roles:

- Admin/owner.
- Practice manager.
- Veterinarian.
- Technician/nurse.
- Receptionist.

Roles are fixed in v1 but backed by named permission capabilities internally.

Non-negotiable rules:

- Only veterinarians can sign/finalize medical notes.
- Only veterinarians can approve prescriptions.
- Only veterinarians can approve AI-generated medical content before it becomes part of the signed medical record or leaves the clinic under clinical authority.

No co-signing/supervising vet workflow in v1.

## AI Scope

### Allowed AI Features

AI v1 may support documentation and administrative communication drafts:

- Draft SOAP notes from structured intake/checklist/rough notes.
- Draft discharge instructions/client summaries.
- Summarize patient history.
- Draft follow-up/admin message text for staff to copy/send elsewhere.
- Translate medical jargon into client-friendly language.
- Flag missing or contradictory information.

### Disallowed AI Features

AI must not:

- Diagnose autonomously.
- Prescribe autonomously.
- Recommend treatment autonomously.
- Send client messages without human approval.
- Finalize medical records.
- Invent missing facts.
- Silently modify problem lists, prescriptions, reminders, or signed notes.

### AI Inputs

V1 starts with:

- Typed rough notes.
- Staff-entered structured forms/templates.

Future:

- Audio recording/transcription after consent, privacy, storage, transcription quality, and UX are solved.
- Client-facing digital intake later.

### AI UX

Primary UX:

- Section-level assistant actions.
- Optional whole-note generation.

Examples:

- Draft SOAP from intake.
- Rewrite Plan as client instructions.
- Summarize patient history.
- Make this concise.
- Flag missing fields.
- Regenerate one SOAP section with diff/review.

Avoid chatbot-first UX.

### AI Safety and Audit

AI must:

- Flag missing/uncertain information.
- Use explicit placeholders where needed.
- Never silently generate a complete-looking note from incomplete data.
- Store source inputs used, generated draft, edits, timestamps, signer, model/version, and prompt/config metadata when real AI is used.

Prototype implementation:

- `AiDraftingService` interface.
- Mock provider by default for deterministic demos/tests.
- Optional real provider adapter behind configuration.

AI vendor policy:

- No training on clinic data.
- Minimal vendor retention.
- Encrypted transmission.
- Logged model/version usage.
- Bring-your-own-provider/key may be added later.

## Client Communication

V1 includes:

- Generated documents.
- Draft messages.
- Printable/exportable discharge instructions and visit summaries.

V1 does not include:

- Built-in outbound SMS/email.
- Two-way client messaging inbox.
- Client portal.

## Estimates, Prescriptions, Catalog

### Estimates

V1 includes basic treatment estimates only.

- Estimates may be generated from SOAP plan items.
- Estimates are editable independently so price/quantity/options can change without corrupting the medical plan.
- No full invoicing, POS, payments, refunds, taxes, reconciliation, or accounting.

### Medication/Procedure Catalog

V1 includes:

- Medication/procedure catalog.
- Names.
- Common instructions.
- Prices for estimates.

V1 does not include full stock/inventory tracking.

### Prescriptions

V1 includes prescription records:

- Medication.
- Dose.
- Route.
- Frequency.
- Duration.
- Prescribing vet.
- Printable label/instructions if practical.

AI may draft instructions, but prescription fields must be explicitly reviewed and approved by a veterinarian.

## Diagnostics and Attachments

V1 supports attachments only:

- Lab PDFs.
- Images/radiographs.
- Dental charts/photos.
- Referral documents.
- Consent forms.
- Historical records.

V1 does not include:

- Lab integrations.
- Structured lab result entry as a core feature.
- AI interpretation of diagnostics.

## Reminders/Recalls

V1 includes:

- Manual reminder records.
- Light rule-based vaccine/preventive due dates.
- Upcoming/overdue reminder views or exports.

V1 does not include automated SMS/email reminder sending.

## Templates and Customization

V1 customization is limited to templates/catalog.

Supported:

- System default templates.
- Clinic-level editable templates.
- Wellness visit template.
- Vaccine visit template.
- Sick visit template later.
- Discharge instruction snippets.
- Estimate/catalog items.
- Common medication instructions.

Not v1:

- Per-user templates.
- Marketplace/shared templates.
- Custom workflow builder.
- Custom permission builder.

AI fills selected template fields from source input and may suggest a template choice, but does not silently choose or switch templates.

## Migration, Import, Export

### Import

Pilot migration story:

- CSV import clients/patients/households.
- Historical records imported as attachments/PDFs linked to patient timeline.
- No full structured PMS migration in v1.

### Export

Clinics should have clear exit rights:

- Patient chart PDF export.
- Core data CSV export.
- Visits/notes CSV or JSON export if feasible.
- Clients/patients CSV.
- Attachments downloadable.

No FHIR or standard API export in v1.

## Analytics and Reporting

V1 includes operational basics:

- Unsigned notes.
- Notes signed same day.
- Median time to sign.
- Visits by status.
- Today board bottlenecks.
- Reminders due.
- AI draft usage/acceptance.
- Missing-field flags.

Avoid business dashboards without billing data.

## Security, Privacy, Compliance Posture

Build with medical-record-grade security inspired by HIPAA-grade practices, without overclaiming region-specific legal compliance at launch.

Minimum posture:

- Role-based access control.
- Audit logs.
- Encryption in transit.
- Encryption at rest where platform-supported.
- Secure backups.
- Signed-note immutability via snapshots/amendments.
- Configurable export/retention later.
- AI vendor data-processing controls.
- No AI training on clinic data unless explicitly opted in.

Audit log v1 scope:

- Clinical mutations.
- AI generations.
- Note sign/amend events.
- Prescription approvals.
- Attachment changes.
- User/role/settings changes.
- Template/catalog changes.

Audit logs are append-only at the application level in v1, with design room for stronger database enforcement later.

Do not audit every read/view in v1.

## Architecture Direction

Implementation direction:

- Conventional web SaaS.
- Postgres as source of truth.
- Modular monolith.

Tenant model:

- Organization tenant with one or more clinic locations.
- V1 UI optimized for one location.
- Clinical records belong to organization and usually a location.

Membership model:

- Global user identity.
- User can belong to multiple organizations.
- Per-organization membership and role.
- Location access can be added later.

Suggested internal modules:

- Identity/access control.
- Organizations/locations.
- Households/clients/patients.
- Visits/today board.
- Clinical records/notes.
- AI drafting.
- Templates/catalog.
- Prescriptions/reminders.
- Estimates/documents.
- Attachments/storage.
- Audit log.
- Reporting.

## Explicit V1 Anti-Scope

V1 must not include:

- Full PMS replacement.
- Full appointment calendar/online booking.
- Full billing/POS/payment processing.
- Accounting/reconciliation.
- Full inventory/stock/lot/expiry tracking.
- Lab integrations.
- AI diagnostic interpretation.
- Autonomous clinical AI.
- Built-in SMS/email sending.
- Two-way client messaging.
- Client portal.
- Native mobile apps.
- Marketplace templates.
- Custom workflow/role builders.
- Full structured migration from existing PMS.

## Next Documents

1. `docs/architecture.md` — tenant/auth/domain/data model and module boundaries.
2. `docs/adr/` — major architectural decisions as they harden.
3. Implementation task breakdown for the wellness visit vertical slice.
