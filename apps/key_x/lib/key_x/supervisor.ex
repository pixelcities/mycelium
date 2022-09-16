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

    dynamic = []
    children = []

    Supervisor.init(children ++ dynamic, strategy: :one_for_one)
  end

  def callback(tenant), do: create_repo(tenant)

  defp create_repo(tenant) do
    KeyX.Repo.query('CREATE SCHEMA IF NOT EXISTS "#{tenant}"')
    {:ok, _, _} = Ecto.Migrator.with_repo(KeyX.Repo, &Ecto.Migrator.run(&1, :up, all: true, prefix: tenant))
  end

  defp register(registry, weight \\ 10) do
    Registry.register(registry, "start", {weight, __MODULE__, :callback})
  end
end
