defmodule Maestro.TenantSupervisor do
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
      {DynamicSupervisor, name: Maestro.DynamicTenantSupervisor, strategy: :one_for_one}
    ]

    children = Enum.flat_map(tenants, fn tenant -> get_children(tenant) end)

    Supervisor.init(children ++ dynamic, strategy: :one_for_one)
  end

  def callback(tenant) do
    create_repo(tenant)
    start_children(tenant)
  end

  defp create_repo(tenant) do
    Maestro.Repo.query('CREATE SCHEMA IF NOT EXISTS "#{tenant}"')
    {:ok, _, _} = Ecto.Migrator.with_repo(Maestro.Repo, &Ecto.Migrator.run(&1, :up, all: true, prefix: tenant))
  end

  defp start_children(tenant) do
    Enum.each(get_children(tenant), fn spec ->
      DynamicSupervisor.start_child(Maestro.DynamicTenantSupervisor, spec)
    end)
  end

  defp get_children(tenant) do
    backend = Maestro.Application.get_app()

    [
      {Maestro.Projectors.Task, application: Module.concat(backend, tenant)},
      {Maestro.Managers.TransformerTaskProcessManager, application: Module.concat(backend, tenant)}
    ]
  end

  defp register(registry, weight \\ 10) do
    Registry.register(registry, "start", {weight, __MODULE__, :callback})
  end

end
