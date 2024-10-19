defmodule RefreshTokenExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      RefreshTokenExampleWeb.Telemetry,
      RefreshTokenExample.Repo,
      {DNSCluster, query: Application.get_env(:refresh_token_example, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: RefreshTokenExample.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: RefreshTokenExample.Finch},
      # Start a worker by calling: RefreshTokenExample.Worker.start_link(arg)
      # {RefreshTokenExample.Worker, arg},
      # Start to serve requests, typically the last entry
      RefreshTokenExampleWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: RefreshTokenExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RefreshTokenExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
