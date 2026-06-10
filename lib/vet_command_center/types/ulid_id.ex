defmodule VetCommandCenter.Types.UlidId do
  @moduledoc """
  Custom Ecto type that stores ULIDs as binary(26) in the database.

  This ensures all IDs are time-sortable, unique across distributed systems,
  and fit within Postgres's binary(26) column type.

  ## Usage

      schema "my_table" do
        field :id, VetCommandCenter.Types.UlidId, primary_key: true
        ...
      end

  ## Generating IDs

  The `VetCommandCenter.Ulid` helper module provides convenient ULID generation:

      VetCommandCenter.Ulid.generate()
      # => "01HK6HBW2X7A9BQ5J3F8M0N1P2"
  """

  use Ecto.Type

  @type t :: String.t()

  @impl true
  def type, do: :string

  @impl true
  def cast(ulid) when is_binary(ulid) and byte_size(ulid) == 26 do
    {:ok, ulid}
  end

  def cast(ulid) when is_binary(ulid) do
    {:error, message: "expected ULID to be exactly 26 characters, got #{byte_size(ulid)}"}
  end

  def cast(_), do: {:error, message: "expected ULID to be a 26-character string"}

  @impl true
  def load(ulid) when is_binary(ulid) and byte_size(ulid) == 26, do: {:ok, ulid}
  def load(_), do: {:error, message: "failed to load ULID from database"}

  @impl true
  def dump(ulid) when is_binary(ulid) and byte_size(ulid) == 26, do: {:ok, ulid}
  def dump(_), do: :error

  @impl true
  def equal?(a, b), do: a == b
end
