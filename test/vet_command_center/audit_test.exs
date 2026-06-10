defmodule VetCommandCenter.AuditTest do
  use VetCommandCenter.DataCase, async: true
  alias VetCommandCenter.Audit
  alias VetCommandCenter.Audit.AuditEvent

  @user_id "01HK6HBW2X7A9BQ5J3F8M0N1P3"

  # Each test gets its own org ID to avoid cross-contamination in the sandbox
  defp org_id(test_name), do: "ORG_#{test_name}"

  describe "log/1" do
    test "inserts a minimal audit event" do
      org = org_id("minimal")

      {:ok, event} =
        Audit.log(%{
          organization_id: org,
          event_type: "test.event"
        })

      assert %AuditEvent{} = event
      assert event.organization_id == org
      assert event.event_type == "test.event"
      assert is_binary(event.id)
      assert byte_size(event.id) == 26
    end

    test "inserts a full audit event with all fields" do
      org = org_id("full")

      {:ok, event} =
        Audit.log(%{
          organization_id: org,
          clinic_location_id: "01HK6HBW2X7A9BQ5J3F8M0N1P4",
          actor_user_id: @user_id,
          actor_staff_profile_id: "01HK6HBW2X7A9BQ5J3F8M0N1P5",
          event_type: "patient.created",
          target_type: "patient",
          target_id: "01HK6HBW2X7A9BQ5J3F8M0N1P6",
          metadata: %{name: "Buddy", species: "dog"},
          ip_address: "127.0.0.1",
          user_agent: "TestAgent/1.0"
        })

      assert event.clinic_location_id == "01HK6HBW2X7A9BQ5J3F8M0N1P4"
      assert event.actor_user_id == @user_id
      assert event.target_type == "patient"
      assert event.metadata == %{name: "Buddy", species: "dog"}
      assert event.actor_snapshot == %{}
    end

    test "rejects events without required fields" do
      {:error, changeset} = Audit.log(%{event_type: "test.event"})
      assert changeset.errors[:organization_id]

      {:error, changeset} = Audit.log(%{organization_id: org_id("missing")})
      assert changeset.errors[:event_type]
    end
  end

  describe "log!/1" do
    test "inserts and returns the event" do
      org = org_id("bang")

      event =
        Audit.log!(%{
          organization_id: org,
          event_type: "test.event"
        })

      assert %AuditEvent{} = event
    end
  end

  describe "log_with_actor/3" do
    test "enriches event with actor info" do
      org = org_id("actor")
      user = %{id: @user_id, name: "Dr. Smith"}
      staff = %{id: "01HK6HBW2X7A9BQ5J3F8M0N1P7", role: "veterinarian"}

      {:ok, event} =
        Audit.log_with_actor(
          %{
            organization_id: org,
            event_type: "patient.created",
            target_type: "patient",
            metadata: %{name: "Buddy"}
          },
          user,
          staff,
          %{display_name: "Dr. Smith", role: "veterinarian"}
        )

      assert event.actor_user_id == @user_id
      assert event.actor_staff_profile_id == "01HK6HBW2X7A9BQ5J3F8M0N1P7"
      assert event.metadata == %{name: "Buddy"}
      assert event.actor_snapshot == %{display_name: "Dr. Smith", role: "veterinarian"}
    end

    test "works without staff profile" do
      org = org_id("no_staff")
      user = %{id: @user_id}

      {:ok, event} =
        Audit.log_with_actor(
          %{
            organization_id: org,
            event_type: "test.event"
          },
          user
        )

      assert event.actor_user_id == @user_id
      assert is_nil(event.actor_staff_profile_id)
    end
  end

  describe "log_many/1" do
    test "inserts multiple events in a transaction" do
      org = org_id("many")

      events = [
        %{organization_id: org, event_type: "patient.created", target_type: "patient"},
        %{organization_id: org, event_type: "visit.scheduled", target_type: "visit"}
      ]

      {:ok, results} = Audit.log_many(events)
      assert length(results) == 2
    end
  end

  describe "list_events/2" do
    test "returns events for an organization" do
      org = org_id("list")

      Audit.log!(%{organization_id: org, event_type: "test.first"})
      Audit.log!(%{organization_id: org, event_type: "test.second"})

      events = Audit.list_events(org)
      assert length(events) == 2

      # Most recent first
      assert hd(events).event_type == "test.second"
    end

    test "returns empty list for unknown org" do
      events = Audit.list_events("nonexistent-org-id")
      assert events == []
    end

    test "respects limit option" do
      org = org_id("limit")

      Audit.log!(%{organization_id: org, event_type: "test.limit1"})
      Audit.log!(%{organization_id: org, event_type: "test.limit2"})
      Audit.log!(%{organization_id: org, event_type: "test.limit3"})

      events = Audit.list_events(org, limit: 2)
      assert length(events) == 2
    end
  end

  describe "list_events_for_target/3" do
    test "returns events for a specific target" do
      org = org_id("target")
      patient_id = "01HK6HBW2X7A9BQ5J3F8M0N1P8"

      Audit.log!(%{
        organization_id: org,
        event_type: "patient.created",
        target_type: "patient",
        target_id: patient_id
      })

      Audit.log!(%{
        organization_id: org,
        event_type: "visit.scheduled",
        target_type: "visit"
      })

      events = Audit.list_events_for_target(org, "patient", patient_id)
      assert length(events) == 1
      assert hd(events).event_type == "patient.created"
    end
  end

  describe "list_events_by_actor/2" do
    test "returns events for a specific actor" do
      org = org_id("actor_list")

      Audit.log!(%{
        organization_id: org,
        event_type: "test.actor",
        actor_user_id: @user_id
      })

      Audit.log!(%{
        organization_id: org,
        event_type: "test.other",
        actor_user_id: "01HK6HBW2X7A9BQ5J3F8M0N1P9"
      })

      events = Audit.list_events_by_actor(org, @user_id)
      assert length(events) == 1
      assert hd(events).actor_user_id == @user_id
    end
  end

  describe "list_events_by_prefix/2" do
    test "returns events matching a type prefix" do
      org = org_id("prefix")

      Audit.log!(%{organization_id: org, event_type: "patient.created"})
      Audit.log!(%{organization_id: org, event_type: "patient.updated"})
      Audit.log!(%{organization_id: org, event_type: "visit.scheduled"})

      events = Audit.list_events_by_prefix(org, "patient")
      assert length(events) == 2
    end
  end
end
