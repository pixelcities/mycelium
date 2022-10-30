defmodule LiaisonServer.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    tenants = Landlord.Tenants.get!()
    register(Landlord.Registry, 0)

    app = tenants
      |> Enum.map(fn tenant -> {LiaisonServer.App, name: Module.concat(LiaisonServer.App, tenant), tenant: tenant} end)

    dynamic = [
      {DynamicSupervisor, name: LiaisonServer.AppSupervisor, strategy: :one_for_one},
      {DynamicSupervisor, name: LiaisonServer.RelayEventSupervisor, strategy: :one_for_one}
    ]

    # We manage the supervisors for our children because they depend on our main app
    deps = [
      {MetaStore.TenantSupervisor, registry: Landlord.Registry, tenants: tenants},
      {DataStore.TenantSupervisor, registry: Landlord.Registry, tenants: tenants},
      {KeyX.TenantSupervisor, registry: Landlord.Registry, tenants: tenants},
      {Maestro.TenantSupervisor, registry: Landlord.Registry, tenants: tenants},
      {ContentServer.TenantSupervisor, registry: Landlord.Registry, tenants: tenants}
    ]

    children = [
      {Phoenix.PubSub, name: LiaisonServer.PubSub},
      {LiaisonServerWeb.Tracker, name: LiaisonServerWeb.Tracker, pubsub_server: LiaisonServer.PubSub},
      LiaisonServerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: LiaisonServer.Supervisor]
    Supervisor.start_link(app ++ dynamic ++ deps ++ children, opts)
  end

  def callback(application) do
    init_event_store!(application)
    start_children(application)
  end

  @doc """
  Starts the main commanded application for future tenants

  Tenants that already exist during startup are added in the
  static supervisor tree, as they should exist before anything
  else in spawned.

  This means that the dynamic supervisor should mostly be empty,
  and will "flush" after restarts.
  """
  def start_children(application) do
    children = [
      {LiaisonServer.App, name: Module.concat(LiaisonServer.App, application), tenant: application}
    ]

    Enum.each(children, fn spec ->
      DynamicSupervisor.start_child(LiaisonServer.AppSupervisor, spec)
    end)
  end

  def init_event_store!(name) when is_atom(name), do: init_event_store!(Atom.to_string(name))
  def init_event_store!(name) do
    event_store = hd(Application.get_env(:liaison_server, :event_stores, []))
    config = event_store.config()
    config = Keyword.put(config, :schema, name)

    case EventStore.Storage.Schema.create(config) do
      :ok -> EventStore.Tasks.Init.exec(config, [quiet: true])
      {:error, :already_up} -> :ok
      {:error, error} -> raise error
    end
  end

  defp register(registry, weight) do
    Registry.register(registry, "start", {weight, __MODULE__, :callback})
  end

end
