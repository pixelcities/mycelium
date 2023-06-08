defmodule MetaStore.InMemoryEventStoreCase do
  @moduledoc false

  @doc false
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case

      defp event_store(_context) do
        {:ok, _apps} = Application.ensure_all_started(:meta_store)

        on_exit(fn ->
          :ok = Application.stop(:meta_store)
        end)
      end
    end
  end
end
