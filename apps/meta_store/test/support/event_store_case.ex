defmodule MetaStore.InMemoryEventStoreCase do
  use ExUnit.CaseTemplate

  alias Commanded.EventStore.Adapters.InMemory

  setup do
    {:ok, _apps} = Application.ensure_all_started(:meta_store)

    on_exit(fn ->
      :ok = Application.stop(:meta_store)
    end)
  end
end
