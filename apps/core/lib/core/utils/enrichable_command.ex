defmodule Core.Utils.EnrichableCommand do
  defmacro __using__(schema) do
    quote do
      use Commanded.Command,
        unquote(schema) ++ [__metadata__: :map]
    end
  end
end

