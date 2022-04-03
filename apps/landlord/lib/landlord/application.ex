defmodule Landlord.Application do
  @moduledoc """
  Landlord contains user information for both internal and external use

  There is some commanded functionality, but this is for integration with other
  apps and is not expected to be used standalone. For this reason the commanded
  app will not be started by default.
  """

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Landlord.Repo,
      {Landlord.Registry, name: Landlord.Registry}
    ]

    opts = [strategy: :one_for_one, name: Landlord.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end

  def get_app() do
    Application.fetch_env!(:landlord, :backend_config)[:backend_app]
  end
end
