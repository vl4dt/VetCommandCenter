defmodule VetCommandCenter.Repo.Migrations.CreateAuditEvents do
  @moduledoc """
  Creates the append-only audit_events table.

  This table records every significant action in the system for compliance,
  debugging, and operational reporting. Each row is immutable once inserted.
  """

  use Ecto.Migration

  def change do
    create table(:audit_events, primary_key: false) do
      add :id, :string, size: 26, null: false, comment: "ULID primary key (time-sortable)"
      add :organization_id, :string, null: false, comment: "Organization this event belongs to"
      add :clinic_location_id, :string, comment: "Optional clinic location within the org"
      add :actor_user_id, :string, comment: "User who triggered the event"
      add :actor_staff_profile_id, :string, comment: "Staff profile of the actor"
      add :event_type, :string, null: false, comment: "Dotted action type (e.g. patient.created)"
      add :target_type, :string, comment: "Entity type affected (e.g. patient)"
      add :target_id, :string, comment: "ID of the affected entity"

      add :metadata, :map,
        null: false,
        default: %{},
        comment: "JSON metadata with event-specific details"

      add :actor_snapshot, :map,
        null: false,
        default: %{},
        comment: "Denormalized actor display/role data at event time"

      add :ip_address, :string, comment: "Client IP address"
      add :user_agent, :string, comment: "Client user agent string"

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:audit_events, [:id])
    create index(:audit_events, [:organization_id])
    create index(:audit_events, [:actor_user_id])
    create index(:audit_events, [:event_type])
    create index(:audit_events, [:target_type, :target_id])
    create index(:audit_events, [:inserted_at])
  end
end
