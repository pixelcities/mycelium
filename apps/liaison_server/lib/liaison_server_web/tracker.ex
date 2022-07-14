defmodule LiaisonServerWeb.Tracker do
  use Phoenix.Tracker

  alias Maestro.Allocator

  def start_link(opts) do
    opts = Keyword.merge([name: __MODULE__], opts)
    Phoenix.Tracker.start_link(__MODULE__, opts, opts)
  end

  def init(opts) do
    server = Keyword.fetch!(opts, :pubsub_server)
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  def handle_diff(diff, state) do
    for {_topic, {joins, leaves}} <- diff do
      for {key, meta} <- joins do
        Allocator.register_worker(key, meta)
      end
      for {key, _meta} <- leaves do
        Allocator.deregister_worker(key)
      end
    end
    {:ok, state}
  end
end
