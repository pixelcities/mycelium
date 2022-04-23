defmodule Maestro.InMemoryEventStoreCase do
  use ExUnit.CaseTemplate

  alias Commanded.EventStore.Adapters.InMemory

  setup do
    {:ok, _apps} = Application.ensure_all_started(:maestro)

    on_exit(fn ->
      :ok = Application.stop(:maestro)
    end)
  end
end
