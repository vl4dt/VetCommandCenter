defmodule VetCommandCenter.Audit do
  @moduledoc """
  Audit context — append-only event logging.

  Provides helper functions to record audit events in a consistent way.
  All events are immutable once inserted and can be queried for compliance,
  debugging, and operational reporting.

  ## Event Types

  Convention: `<target>.<action>` where action is one of:
  - `created` — new entity
  - `updated` — entity modified
  - `deleted` — entity removed (soft or hard)
  - `signed_in` / `signed_out` — auth events
  - `prescribed` — prescription issued
  - `reminded` — reminder triggered
  - Custom: any domain-specific action

  ## Examples

      # Record a patient creation
      VetCommandCenter.Audit.log(%{
        organization_id: org.id,
        event_type: "patient.created",
        target_type: "patient",
        target_id: patient.id,
        actor_user_id: current_user.id,
        metadata: %{name: patient.name}
      })

      # Record with actor snapshot (full context)
      VetCommandCenter.Audit.log_with_actor(%{
        organization_id: org.id,
        event_type: "patient.updated",
        target_type: "patient",
        target_id: patient.id,
        metadata: %{changes: %{"weight" => "5.2"}}
      }, current_user, staff_profile)
  """

  import Ecto.Query
  alias VetCommandCenter.Repo
  alias VetCommandCenter.Audit.AuditEvent

  @type event_attrs :: map()
  @type actor_snapshot :: map()

  @doc """
  Logs a single audit event.

  Accepts a map with the fields needed for `AuditEvent.changeset/2`.
  Returns `{:ok, AuditEvent}` or `{:error, Ecto.Changeset}`.
  """
  @spec log(event_attrs()) :: {:ok, AuditEvent.t()} | {:error, Ecto.Changeset.t()}
  def log(attrs) when is_map(attrs) do
    %AuditEvent{}
    |> AuditEvent.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Logs a single audit event, raising on failure.

  Useful in contexts where a failed audit log should halt the operation.
  """
  @spec log!(event_attrs()) :: AuditEvent.t()
  def log!(attrs) when is_map(attrs) do
    %AuditEvent{}
    |> AuditEvent.changeset(attrs)
    |> Repo.insert!()
  end

  @doc """
  Logs an audit event with full actor context.

  Takes the base event attrs and enriches them with actor information:
  - `actor_user_id` from the user struct's `id`
  - `actor_staff_profile_id` from the staff profile (if present)
  - An `actor_snapshot` containing denormalized display name, role, etc.

  The `user` argument should be a user struct with an `id` field.
  The `staff_profile` argument is optional and should have an `id` field.
  """
  @spec log_with_actor(
          event_attrs(),
          map(),
          map() | nil,
          actor_snapshot() | nil
        ) :: {:ok, AuditEvent.t()} | {:error, Ecto.Changeset.t()}
  def log_with_actor(attrs, user, staff_profile \\ nil, actor_snapshot \\ nil) do
    enriched_attrs =
      attrs
      |> Map.put_new(:actor_user_id, user.id)
      |> Map.put_new(:actor_staff_profile_id, if(staff_profile, do: staff_profile.id))
      |> put_actor_snapshot(actor_snapshot)

    log(enriched_attrs)
  end

  @doc """
  Logs multiple audit events in a single transaction.

  Accepts a list of event attribute maps. All are inserted together,
  or none if any fail.
  """
  @spec log_many([event_attrs()]) :: {:ok, [AuditEvent.t()]} | {:error, Ecto.Changeset.t()}
  def log_many(attrs_list) when is_list(attrs_list) do
    Repo.transaction(fn ->
      for attrs <- attrs_list do
        %AuditEvent{}
        |> AuditEvent.changeset(attrs)
        |> Repo.insert!()
      end
    end)
  end

  @doc """
  Returns all audit events for an organization, most recent first.

  Supports pagination via `limit` and `offset`.
  """
  @spec list_events(String.t(), keyword()) :: [AuditEvent.t()]
  def list_events(organization_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 50)
    offset = Keyword.get(opts, :offset, 0)

    AuditEvent
    |> AuditEvent.by_organization(organization_id)
    |> AuditEvent.most_recent()
    |> limit(^limit)
    |> offset(^offset)
    |> Repo.all()
  end

  @doc """
  Returns audit events for a specific target entity.
  """
  @spec list_events_for_target(String.t(), String.t(), String.t()) :: [AuditEvent.t()]
  def list_events_for_target(organization_id, target_type, target_id) do
    AuditEvent
    |> AuditEvent.by_organization(organization_id)
    |> AuditEvent.by_target(target_type, target_id)
    |> AuditEvent.most_recent()
    |> Repo.all()
  end

  @doc """
  Returns audit events for a specific actor user within an organization.
  """
  @spec list_events_by_actor(String.t(), String.t()) :: [AuditEvent.t()]
  def list_events_by_actor(organization_id, user_id) do
    AuditEvent
    |> AuditEvent.by_organization(organization_id)
    |> AuditEvent.by_actor(user_id)
    |> AuditEvent.most_recent()
    |> Repo.all()
  end

  @doc """
  Returns audit events matching an event type prefix within an organization.

  For example, `list_events_by_prefix(org_id, "patient")` returns all
  patient-related events (patient.created, patient.updated, etc.).
  """
  @spec list_events_by_prefix(String.t(), String.t()) :: [AuditEvent.t()]
  def list_events_by_prefix(organization_id, prefix) do
    AuditEvent
    |> AuditEvent.by_organization(organization_id)
    |> AuditEvent.by_event_prefix(prefix)
    |> AuditEvent.most_recent()
    |> Repo.all()
  end

  # -- Private helpers --

  defp put_actor_snapshot(attrs, nil), do: attrs

  defp put_actor_snapshot(attrs, snapshot) when is_map(snapshot) do
    Map.put_new(attrs, :actor_snapshot, snapshot)
  end
end
