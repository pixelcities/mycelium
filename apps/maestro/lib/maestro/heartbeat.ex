defmodule Maestro.Heartbeat do
  use GenServer

  @interval 60_000

  alias Maestro.Allocator


  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, opts)
  end

  def init(_) do
    :timer.send_interval(@interval, :send)
    {:ok, 0}
  end

  def handle_info(:send, state) do
    clock = state + @interval

    tick(clock)

    {:noreply, clock}
  end

  defp tick(_clock) do
    Allocator.clean_workers()
    Allocator.assign_workers()
  end

end
