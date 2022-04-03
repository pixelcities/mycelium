defmodule DataStore.Application do
  @moduledoc false

  @parent_module __MODULE__ |> Module.split |> Enum.drop(-1) |> Module.concat

  use Application

  @impl true
  def start(_type, _args) do
    # app = Application.fetch_env!(:data_store, :backend_config)[:backend_app]
    app = get_app()
    tenants = Landlord.Registry.get()

    # Refrain from loading the local app when we have a central backend (e.g. LiaisonServer)
    children = if app == @parent_module.App do
      Enum.flat_map(tenants, fn tenant ->
        [
          {DataStore.App, name: Module.concat([app, tenant]), tenant: tenant}
        ]
      end) ++ [
        {DataStore.Supervisor, backend: app, tenants: tenants}
      ]
    else
      []
    end

    opts = [strategy: :one_for_one, name: DataStore.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end

  def get_app() do
    Application.fetch_env!(:data_store, :backend_config)[:backend_app]
  end

end
