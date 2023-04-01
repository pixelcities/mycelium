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
      LiaisonServerWeb.Endpoint,
      {Core.Timeline, name: Core.Timeline}
    ]

    opts = [strategy: :one_for_one, name: LiaisonServer.Supervisor]
    Supervisor.start_link(app ++ dynamic ++ deps ++ children, opts)
  end

  def start(application) do
    init_event_store!(application)
    start_child(application)
  end

  def stop(application) do
    stop_child(application)
    destroy_event_store!(application)
  end

  @doc """
  Starts the main commanded application for future tenants

  Tenants that already exist during startup are added in the
  static supervisor tree, as they should exist before anything
  else in spawned.

  This means that the dynamic supervisor should mostly be empty,
  and will "flush" after restarts.
  """
  def start_child(application) do
    children = [
      {LiaisonServer.App, name: Module.concat(LiaisonServer.App, application), tenant: application}
    ]

    Enum.each(children, fn spec ->
      DynamicSupervisor.start_child(LiaisonServer.AppSupervisor, spec)
    end)
  end

  @doc """
  Stop the main commanded application for a tenant

  It is unknown if this tenant lives in the dynamic supervisor or not. Because
  there is no id in the dynamic supervision tree we query the process for its
  registered_name, which corresponds to our expected module naming structure.

  Finally, we terminate the child from whichever supervision tree.
  """
  def stop_child(application) do
    # First check if it is part of the dynamic supervision tree
    pid = DynamicSupervisor.which_children(LiaisonServer.AppSupervisor)
      |> Enum.reduce_while(nil, fn {_, pid, _, _}, _ ->
        case Keyword.get(Process.info(pid), :registered_name) do
          nil -> {:cont, nil}
          name ->
            if Enum.at(Module.split(name), -1) == Atom.to_string(application) do
              {:halt, pid}
            else
              {:cont, nil}
            end
        end
      end)

    if pid do
      DynamicSupervisor.terminate_child(LiaisonServer.AppSupervisor, pid)
    else
      Supervisor.terminate_child(LiaisonServer.Supervisor, Module.concat(LiaisonServer.App, application))
      Supervisor.delete_child(LiaisonServer.Supervisor, Module.concat(LiaisonServer.App, application))
    end
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

  def destroy_event_store!(name) when is_atom(name), do: destroy_event_store!(Atom.to_string(name))
  def destroy_event_store!(name) do
    event_store = hd(Application.get_env(:liaison_server, :event_stores, []))
    config = event_store.config()
    config = Keyword.put(config, :schema, name)

    case EventStore.Storage.Schema.drop(config) do
      :ok -> :ok
      {:error, :already_down} -> :ok
      {:error, error} -> raise error
    end
  end

  defp register(registry, weight) do
    Registry.register(registry, "start", {weight, __MODULE__, :start})
    Registry.register(registry, "stop", {100-weight, __MODULE__, :stop})
  end

end
