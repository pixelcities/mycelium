defmodule Maestro.Heartbeat do
  use GenServer

  @interval 60_000

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

    {:noreply, clock}
  end
end
