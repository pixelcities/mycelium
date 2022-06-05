defmodule KeyX.TenantSupervisor do
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(args) do
    registry = Keyword.fetch!(args, :registry)
    tenants = Keyword.fetch!(args, :tenants)

    dynamic = []
    children = []

    Supervisor.init(children ++ dynamic, strategy: :one_for_one)
  end

end
