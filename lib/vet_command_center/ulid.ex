defmodule VetCommandCenter.Ulid do
  @moduledoc """
  ULID generation helpers.

  Wraps the `Ulid` library to provide a consistent interface
  for generating time-sortable, unique identifiers across all schemas.

  ## Examples

      iex> VetCommandCenter.Ulid.generate()
      "01HK6HBW2X7A9BQ5J3F8M0N1P2"

      iex> VetCommandCenter.Ulid.generate() |> VetCommandCenter.Ulid.valid?()
      true
  """

  @spec generate :: String.t()
  defdelegate generate(), to: Ulid

  @spec valid?(any()) :: boolean()
  def valid?(ulid) when is_binary(ulid) do
    byte_size(ulid) == 26 &&
      ulid =~ ~r/^[0-7][0-9A-HJKMNP-TV-Z]{25}$/i
  end

  def valid?(_), do: false
end
