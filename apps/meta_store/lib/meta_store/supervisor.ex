defmodule MetaStore.Supervisor do
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
          {MetaStore.Workflows.AddCollectionInput, application: Module.concat(backend, tenant)},
          {MetaStore.Projectors.Source, application: Module.concat(backend, tenant)},
          {MetaStore.Projectors.Collection, application: Module.concat(backend, tenant)}
        ]
      end)
      ++
        [
          MetaStore.Repo
        ]


    Supervisor.init(children, strategy: :one_for_one)
  end
end
