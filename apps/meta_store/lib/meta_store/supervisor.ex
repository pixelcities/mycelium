defmodule MetaStore.TenantSupervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    registry = Keyword.fetch!(args, :registry)
    tenants = Keyword.fetch!(args, :tenants)

    register(registry)

    dynamic = [
      {DynamicSupervisor, name: MetaStore.DynamicTenantSupervisor, strategy: :one_for_one}
    ]

    children = Enum.flat_map(tenants, fn tenant -> get_children(tenant) end)

    Supervisor.init(children ++ dynamic, strategy: :one_for_one)
  end

  def callback(tenant), do: start_children(tenant)

  defp start_children(tenant) do
    Enum.each(get_children(tenant), fn spec ->
      DynamicSupervisor.start_child(MetaStore.DynamicTenantSupervisor, spec)
    end)
  end

  defp get_children(tenant) do
    backend = MetaStore.Application.get_app()

    [
      {MetaStore.Workflows.AddCollectionInput, application: Module.concat(backend, tenant)},
      {MetaStore.Projectors.Source, application: Module.concat(backend, tenant)},
      {MetaStore.Projectors.Collection, application: Module.concat(backend, tenant)}
    ]
  end

  defp register(registry, weight \\ 10) do
    Registry.register(registry, "start", {weight, __MODULE__, :callback})
  end

end
