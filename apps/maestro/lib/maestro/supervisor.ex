defmodule Maestro.Supervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(args) do
    backend = Keyword.fetch!(args, :backend)
    tenants = Keyword.fetch!(args, :tenants)

    children =
      Enum.flat_map(tenants, fn tenant ->
        [
          {Maestro.Managers.TransformerTaskProcessManager, application: Module.concat(backend, tenant)}
        ]
      end)
      ++
        [
          {Maestro.Heartbeat, name: Maestro.Heartbeat}
        ]


    Supervisor.init(children, strategy: :one_for_one)
  end
end
