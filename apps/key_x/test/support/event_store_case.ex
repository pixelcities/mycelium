defmodule KeyX.InMemoryEventStoreCase do
  @moduledoc false

  @doc false
  defmacro __using__(_opts) do
    quote do
      use ExUnit.Case

      defp event_store(_context) do
        {:ok, _apps} = Application.ensure_all_started(:key_x)

        on_exit(fn ->
          :ok = Application.stop(:key_x)
        end)
      end
    end
  end
end
