defmodule Octaspace.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      OctaspaceWeb.Telemetry,
      Octaspace.Repo,
      {DNSCluster, query: Application.get_env(:octaspace, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Octaspace.PubSub},
      # Start a worker by calling: Octaspace.Worker.start_link(arg)
      # {Octaspace.Worker, arg},
      # Start to serve requests, typically the last entry
      OctaspaceWeb.Endpoint,
      {AshAuthentication.Supervisor, [otp_app: :octaspace]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Octaspace.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    OctaspaceWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
