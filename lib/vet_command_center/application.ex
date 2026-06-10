defmodule VetCommandCenter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      VetCommandCenterWeb.Telemetry,
      VetCommandCenter.Repo,
      {DNSCluster,
       query: Application.get_env(:vet_command_center, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: VetCommandCenter.PubSub},
      # Start a worker by calling: VetCommandCenter.Worker.start_link(arg)
      # {VetCommandCenter.Worker, arg},
      # Start to serve requests, typically the last entry
      VetCommandCenterWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: VetCommandCenter.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    VetCommandCenterWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
