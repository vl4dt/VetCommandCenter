defmodule VetCommandCenter.Audit.AuditEvent do
  @moduledoc """
  Append-only audit event schema.

  Every row is immutable once inserted and records who did what, when,
  and from where. The `event_type` field is a short string (e.g. "user.created",
  "patient.updated"), `metadata` stores event-specific JSON details, and
  `actor_snapshot` stores denormalized actor display/role details at event time.

  ## Fields

  - `id` — ULID primary key (time-sortable)
  - `organization_id` — which org this event belongs to (ULID string)
  - `clinic_location_id` — optional location within the org (ULID string)
  - `actor_user_id` — user who triggered the event (ULID string)
  - `actor_staff_profile_id` — staff profile of the actor (ULID string, nullable)
  - `event_type` — dotted string describing the action
  - `target_type` — entity type affected (e.g. "patient", "visit")
  - `target_id` — ID of the affected entity (ULID string, nullable)
  - `metadata` — JSON object with event-specific details
  - `actor_snapshot` — JSON object with actor display/role details at event time
  - `ip_address` — client IP (nullable)
  - `user_agent` — client user agent string (nullable)
  - `inserted_at` — UTC timestamp (auto-set)
  """

  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @primary_key {:id, VetCommandCenter.Types.UlidId, autogenerate: false}
  schema "audit_events" do
    field :organization_id, :string
    field :clinic_location_id, :string
    field :actor_user_id, :string
    field :actor_staff_profile_id, :string
    field :event_type, :string
    field :target_type, :string
    field :target_id, :string
    field :metadata, :map, default: %{}
    field :actor_snapshot, :map, default: %{}
    field :ip_address, :string
    field :user_agent, :string

    timestamps(type: :utc_datetime, updated_at: false)
  end

  @doc """
  Creates a changeset for an audit event.

  All required fields are validated. `metadata` and `actor_snapshot` are
  expected to be maps that will be stored as JSON in the database.

  If no `id` is provided, one is generated automatically via ULID.
  """
  def changeset(audit_event \\ %__MODULE__{}, attrs) do
    audit_event
    |> cast(attrs, [
      :id,
      :organization_id,
      :clinic_location_id,
      :actor_user_id,
      :actor_staff_profile_id,
      :event_type,
      :target_type,
      :target_id,
      :metadata,
      :actor_snapshot,
      :ip_address,
      :user_agent
    ])
    |> maybe_generate_id()
    |> validate_required([:id, :organization_id, :event_type])
    |> validate_map(:metadata)
    |> validate_map(:actor_snapshot)
    |> unique_constraint(:id)
  end

  defp validate_map(changeset, field) do
    case get_field(changeset, field) do
      value when is_map(value) -> changeset
      nil -> put_change(changeset, field, %{})
      _ -> add_error(changeset, field, "must be a map")
    end
  end

  defp maybe_generate_id(changeset) do
    if get_field(changeset, :id) do
      changeset
    else
      put_change(changeset, :id, VetCommandCenter.Ulid.generate())
    end
  end

  @doc """
  Returns a query filtered by organization.
  """
  def by_organization(query \\ __MODULE__, org_id) do
    from(e in query, where: e.organization_id == ^org_id)
  end

  @doc """
  Returns a query filtered by event type prefix (e.g. "patient" matches "patient.created").
  """
  def by_event_prefix(query \\ __MODULE__, prefix) do
    from(e in query, where: like(e.event_type, ^"#{prefix}%"))
  end

  @doc """
  Returns a query filtered by target entity.
  """
  def by_target(query \\ __MODULE__, target_type, target_id) do
    from(e in query,
      where: e.target_type == ^target_type and e.target_id == ^target_id
    )
  end

  @doc """
  Returns a query filtered by actor user.
  """
  def by_actor(query \\ __MODULE__, user_id) do
    from(e in query, where: e.actor_user_id == ^user_id)
  end

  @doc """
  Returns a query ordered by time descending (most recent first).
  """
  def most_recent(query \\ __MODULE__) do
    from(e in query, order_by: [desc: e.inserted_at, desc: e.id])
  end
end
