defmodule Maestro.Application do
  @moduledoc false

  @parent_module __MODULE__ |> Module.split |> Enum.drop(-1) |> Module.concat

  use Application

  @impl true
  def start(_type, _args) do
    app = get_app()
    tenants = Landlord.Tenants.get!()

    commanded = if app == @parent_module.App do
      Enum.flat_map(tenants, fn tenant ->
        [
          {Maestro.App, name: Module.concat([app, tenant]), tenant: tenant}
        ]
      end) ++ [
        {Maestro.TenantSupervisor, registry: Landlord.Registry, tenants: tenants}
      ]
    else
      []
    end

    children = [
      Maestro.Repo,
      {Maestro.Allocator, name: Maestro.Allocator},
      {Maestro.Heartbeat, name: Maestro.Heartbeat}
    ]

    opts = [strategy: :one_for_one, name: Maestro.ApplicationSupervisor]
    Supervisor.start_link(children ++ commanded, opts)
  end

  def get_app() do
    Application.fetch_env!(:maestro, :backend_config)[:backend_app]
  end

end
