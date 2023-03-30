defmodule MetaStore.Aggregates.SourceLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.SourceDeleted

  def after_event(%SourceDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule MetaStore.Aggregates.Source do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            uri: nil,
            schema: nil,
            is_published: false,
            date: nil

  alias MetaStore.Aggregates.Source
  alias Core.Commands.{CreateSource, UpdateSource, DeleteSource}
  alias Core.Events.{SourceCreated, SourceUpdated, SourceDeleted}

  @doc """
  Publish a source
  """
  def execute(%Source{id: nil}, %CreateSource{} = source) do
    SourceCreated.new(source, date: NaiveDateTime.utc_now())
  end

  def execute(%Source{} = source, %UpdateSource{__metadata__: %{user_id: user_id}} = update)
    when source.workspace == update.workspace and hd(source.uri) == hd(update.uri)
  do
    IO.inspect(source.schema)
    IO.inspect(update.schema)

    # TODO: source.schema sometimes has string keys?
    if authorized?(user_id, source.schema) && valid_shares?(user_id, source.schema, update.schema) do
      SourceUpdated.new(update, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end

  def execute(%Source{} = _source, %UpdateSource{} = _update), do: {:error, :invalid_update}

  def execute(%Source{} = source, %DeleteSource{__metadata__: %{user_id: user_id, source_has_collection: source_has_collection, is_admin: is_admin}} = command) do
    if is_admin || authorized?(user_id, source.schema) do
      unless source_has_collection do
        SourceDeleted.new(command,
          uri: source.uri,
          date: NaiveDateTime.utc_now()
        )
      else
        {:error, :source_must_not_be_in_use}
      end
    else
      {:error, :unauthorized}
    end
  end

  defp authorized?(user_id, %{id: _id} = schema) do
    Enum.any?(schema.shares || [], fn share ->
      share.principal == user_id
    end)
  end

  defp authorized?(user_id, %{"id" => _id} = schema) do
    Enum.any?(Map.get(schema, "shares", []), fn share ->
      Map.get(share, "principal") == user_id
    end)
  end

  defp valid_shares?(user_id, original_schema, new_schema) do
    new_columns = Map.new(Enum.map(Map.get(new_schema, "columns", []), fn c -> {Map.get(c, "id"), c} end))

    Enum.reduce_while(original_schema.columns, true, fn column, true ->
      case Map.get(new_columns, column.id) do
        nil -> {:halt, false}
        new_column ->
          if MapSet.new(column.shares) == MapSet.new(Map.get(new_column, "shares")) || Enum.any?(column.shares, fn share -> share.principal == user_id end) do
            {:cont, true}
          else
            {:halt, false}
          end
      end
    end)
  end


  # State mutators

  def apply(%Source{} = source, %SourceCreated{} = created) do
    %Source{source |
      id: created.id,
      workspace: created.workspace,
      uri: created.uri,
      type: created.type,
      schema: created.schema,
      is_published: created.is_published,
      date: created.date
    }
  end

  def apply(%Source{} = source, %SourceUpdated{} = updated) do
    %Source{source |
      schema: updated.schema,
      is_published: updated.is_published,
      date: updated.date
    }
  end

  def apply(%Source{} = source, %SourceDeleted{} = _event), do: source

end
