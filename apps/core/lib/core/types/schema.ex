defmodule Core.Types.Schema do
  use Ecto.Type
  import Ecto.Changeset

  alias Core.Types.Schemas.Schema

  def type, do: Schema

  def cast(%{} = schema) do
    maybe_schema = Schema.new(schema)

    if maybe_schema.valid? do
      {:ok, apply_changes(maybe_schema)}
    else
      {:error, maybe_schema.errors}
    end
  end

  def cast(%Schema{} = schema), do: {:ok, schema}

  def cast(_), do: :error

  def load(_), do: :error

  def dump(%Schema{} = schema), do: {:ok, Schema.dump(schema)}
  def dump(_), do: :error
end

