defmodule DataStore.Application do
  @moduledoc false

  @parent_module __MODULE__ |> Module.split |> Enum.drop(-1) |> Module.concat

  use Application

  @impl true
  def start(_type, _args) do
    app = get_app()
    tenants = Landlord.Tenants.get!()

    # Refrain from loading the local app when we have a central backend (e.g. LiaisonServer)
    commanded = if app == @parent_module.App do
      Enum.flat_map(tenants, fn tenant ->
        [
          {DataStore.App, name: Module.concat(app, tenant), tenant: tenant}
        ]
      end) ++ [
        {DataStore.TenantSupervisor, registry: Landlord.Registry, tenants: tenants}
      ]
    else
      []
    end

    children = []

    opts = [strategy: :one_for_one, name: DataStore.ApplicationSupervisor]
    Supervisor.start_link(children ++ commanded, opts)
  end

  def get_app() do
    Application.fetch_env!(:data_store, :backend_config)[:backend_app]
  end

end
