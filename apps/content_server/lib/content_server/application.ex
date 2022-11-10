defmodule ContentServer.Application do
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
          {ContentServer.App, name: tenant}
        ]
      end) ++ [
        {ContentServer.TenantSupervisor, registry: Landlord.Registry, tenants: tenants}
      ]
    else
      []
    end

    children = [
      ContentServer.Repo,
      {Phoenix.PubSub, name: ContentServer.PubSub},
      {Registry, keys: :duplicate, name: ContentServerWeb.Registry},
      ContentServerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: ContentServer.ApplicationSupervisor]
    Supervisor.start_link(children ++ commanded, opts)
  end

  def get_app() do
    Application.fetch_env!(:content_server, :backend_config)[:backend_app]
  end
end
