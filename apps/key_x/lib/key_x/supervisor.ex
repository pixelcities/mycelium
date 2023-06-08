defmodule KeyX.TenantSupervisor do
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
      {DynamicSupervisor, name: KeyX.DynamicTenantSupervisor, strategy: :one_for_one}
    ]

    children = Enum.flat_map(tenants, fn tenant -> get_children(tenant) end)

    Supervisor.init(children ++ dynamic, strategy: :one_for_one)
  end

  def start(tenant) do
    start_children(tenant)
  end

  def stop(tenant) do
    stop_children(tenant)
  end

  defp start_children(tenant) do
    name = Module.concat(KeyX.ChildSupervisor, tenant)

    DynamicSupervisor.start_child(KeyX.DynamicTenantSupervisor, %{
      id: name,
      start: {Supervisor, :start_link, [get_children(tenant), [name: name, strategy: :one_for_one]]}
    })
  end

  defp stop_children(tenant) do
    pid = DynamicSupervisor.which_children(KeyX.DynamicTenantSupervisor)
      |> Enum.reduce_while(nil, fn {_, pid, _, _}, _ ->
        case Keyword.get(Process.info(pid), :registered_name) do
          nil -> {:cont, nil}
          name -> if Enum.at(Module.split(name), -1) == Atom.to_string(tenant), do: {:halt, pid}, else: {:cont, nil}
        end
      end)

    if pid do
      DynamicSupervisor.terminate_child(KeyX.DynamicTenantSupervisor, pid)
    else
      Enum.each(Supervisor.which_children(KeyX.TenantSupervisor), fn {id, _, _, _} ->
        if Kernel.match?({_, [_ | _]}, id) do
          {_module, opts} = id
          application = Keyword.get(opts, :application)

          if application != nil && Enum.at(Module.split(application), -1) == Atom.to_string(tenant) do
            Supervisor.terminate_child(KeyX.TenantSupervisor, id)
            Supervisor.delete_child(KeyX.TenantSupervisor, id)
          end
        end
      end)
    end
  end

  defp get_children(tenant) do
    backend = KeyX.Application.get_app()

    [
      {KeyX.Projectors.State, application: Module.concat(backend, tenant), name: "Projectors.State." <> Atom.to_string(tenant)}
    ]
  end

  defp register(registry, weight \\ 10) do
    Registry.register(registry, "start", {weight, __MODULE__, :start})
    Registry.register(registry, "stop", {100-weight, __MODULE__, :stop})
  end
end
