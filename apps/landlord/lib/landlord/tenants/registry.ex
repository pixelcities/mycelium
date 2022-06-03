defmodule Landlord.Registry do
  use GenServer

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, opts)
  end

  def get() do
    result = :ets.lookup(__MODULE__, :tenants)
    result[:tenants]
  end

  @impl true
  def init(table) do
    tenants = :ets.new(table, [:set, :protected, :named_table])
    :ets.insert(tenants, {:tenants, [:ds1, :ds2]})

    {:ok, tenants}
  end
end
