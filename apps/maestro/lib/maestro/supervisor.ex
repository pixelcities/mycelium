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

  def start(tenant) do
    create_repo(tenant)
    start_children(tenant)
  end

  def stop(tenant) do
    stop_children(tenant)
    destroy_repo(tenant)
  end


  defp create_repo(tenant) do
    Maestro.Repo.query('CREATE SCHEMA IF NOT EXISTS "#{tenant}"')
    {:ok, _, _} = Ecto.Migrator.with_repo(Maestro.Repo, &Ecto.Migrator.run(&1, :up, all: true, prefix: tenant))
  end

  defp destroy_repo(tenant) do
    Maestro.Repo.query('DROP SCHEMA "#{tenant}" CASCADE')
  end

  defp start_children(tenant) do
    name = Module.concat(Maestro.ChildSupervisor, tenant)

    DynamicSupervisor.start_child(Maestro.DynamicTenantSupervisor, %{
      id: name,
      start: {Supervisor, :start_link, [get_children(tenant), [name: name, strategy: :one_for_one]]}
    })
  end

  defp stop_children(tenant) do
    pid = DynamicSupervisor.which_children(Maestro.DynamicTenantSupervisor)
      |> Enum.reduce_while(nil, fn {_, pid, _, _}, _ ->
        case Keyword.get(Process.info(pid), :registered_name) do
          nil -> {:cont, nil}
          name -> if Enum.at(Module.split(name), -1) == Atom.to_string(tenant), do: {:halt, pid}, else: {:cont, nil}
        end
      end)

    if pid do
      DynamicSupervisor.terminate_child(Maestro.DynamicTenantSupervisor, pid)
    else
      Enum.each(Supervisor.which_children(Maestro.TenantSupervisor), fn {id, _, _, _} ->
        if Kernel.match?({_, [_ | _]}, id) do
          {_module, opts} = id
          application = Keyword.get(opts, :application)

          if application != nil && Enum.at(Module.split(application), -1) == Atom.to_string(tenant) do
            Supervisor.terminate_child(Maestro.TenantSupervisor, id)
            Supervisor.delete_child(Maestro.TenantSupervisor, id)
          end
        end
      end)
    end
  end

  defp get_children(tenant) do
    backend = Maestro.Application.get_app()

    [
      {Maestro.Projectors.Task, application: Module.concat(backend, tenant)},
      {Maestro.Managers.TransformerTaskProcessManager, application: Module.concat(backend, tenant)},
      {Maestro.Managers.WidgetTaskProcessManager, application: Module.concat(backend, tenant)},
      {Maestro.Managers.SourceUpdateProcessManager, application: Module.concat(backend, tenant)}
    ]
  end

  defp register(registry, weight \\ 10) do
    Registry.register(registry, "start", {weight, __MODULE__, :start})
    Registry.register(registry, "stop", {100-weight, __MODULE__, :stop})
  end

end
