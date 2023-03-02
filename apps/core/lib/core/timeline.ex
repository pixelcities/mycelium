defmodule Core.Timeline do
  @moduledoc """
  Keeps track of event causation and correlation

  Store metadata linked to event causation and correlation identifiers. This
  allows future handlers to retrieve interesting information that happened in
  the past.

  Note that state does not persist, this store is meant for a quick lookup or
  for ephemeral data such as throttling.
  """

  use GenServer


  ## Client

  def start_link(opts) do
    name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, name, opts)
  end

  def lookup(correlation_id) do
    GenServer.call(__MODULE__, {:lookup, correlation_id})
  end

  def record(correlation_id, meta) do
    GenServer.cast(__MODULE__, {:record, correlation_id, meta})
  end


  ## Callbacks

  @impl true
  def init(table) do
    events = :ets.new(table, [:set, :protected, :named_table])

    {:ok, events}
  end

  @impl true
  def handle_call({:lookup, id}, _from, events) do
    event = :ets.lookup(events, id)

    response = if length(event) > 0 do
      [{_id, meta}] = event
      {:ok, meta}
    else
      {:error, nil}
    end

    {:reply, response, events}
  end

  @impl true
  def handle_cast({:record, id, meta}, events) do
    event = :ets.lookup(events, id)

    if length(event) == 0 do
      :ets.insert(events, {id, meta})
    end

    {:noreply, events}
  end

end
