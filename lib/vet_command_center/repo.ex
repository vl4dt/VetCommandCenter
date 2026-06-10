defmodule VetCommandCenter.Repo do
  use Ecto.Repo,
    otp_app: :vet_command_center,
    adapter: Ecto.Adapters.Postgres
end
