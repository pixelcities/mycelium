defmodule MetaStore.Aggregates.Source do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            uri: nil,
            schema: nil,
            is_published: false,
            date: nil

  alias MetaStore.Aggregates.Source
  alias Core.Commands.{CreateSource, UpdateSource, UpdateSourceURI, UpdateSourceSchema, DeleteSource}
  alias Core.Events.{SourceCreated, SourceUpdated, SourceURIUpdated, SourceSchemaUpdated, SourceDeleted}

  @doc """
  Publish a source
  """
  def execute(%Source{id: nil}, %CreateSource{} = source) do
    SourceCreated.new(source, date: NaiveDateTime.utc_now())
  end

  def execute(%Source{} = source, %UpdateSource{__metadata__: %{user_id: user_id}} = update)
    when source.workspace == update.workspace and hd(source.uri) == hd(update.uri)
  do
    if authorized?(user_id, source.schema) && valid_shares?(user_id, source.schema, update.schema) do
      SourceUpdated.new(update, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end
  def execute(%Source{} = _source, %UpdateSource{} = _update), do: {:error, :invalid_update}

  def execute(%Source{} = source, %UpdateSourceSchema{__metadata__: %{user_id: user_id, is_internal: is_internal}} = update)
    when source.workspace == update.workspace
  do
    if is_internal || (authorized?(user_id, source.schema) && valid_shares?(user_id, source.schema, update.schema)) do
      SourceSchemaUpdated.new(update, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end
  def execute(%Source{} = _source, %UpdateSourceSchema{} = _update), do: {:error, :invalid_update}

  def execute(%Source{} = source, %UpdateSourceURI{__metadata__: %{user_id: user_id}} = command)
    when source.workspace == command.workspace
  do
    if authorized?(user_id, source.schema) && valid_uri?(hd(source.uri), hd(command.uri)) do
      SourceURIUpdated.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end

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

  defp authorized?(user_id, schema) do
    Enum.any?(schema.shares || [], fn share ->
      share.principal == user_id
    end)
  end

  defp valid_uri?(original_uri, new_uri) do
    # Validate that the URIs are equal, without taking the version into account
    Regex.replace(~r/\/v[0-9]{1,10}$/, original_uri, "") == Regex.replace(~r/\/v[0-9]{1,10}$/, new_uri, "")
  end

  defp valid_shares?(user_id, original_schema, new_schema) do
    new_columns = Map.new(Enum.map(new_schema.columns, fn c -> {c.id, c} end))

    Enum.reduce_while(original_schema.columns, true, fn column, true ->
      case Map.get(new_columns, column.id) do
        nil -> {:halt, false}
        new_column ->
          if MapSet.new(column.shares) == MapSet.new(new_column.shares) || Enum.any?(column.shares, fn share -> share.principal == user_id end) do
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

  def apply(%Source{} = source, %SourceSchemaUpdated{} = updated) do
    %Source{source |
      schema: updated.schema,
      date: updated.date
    }
  end

  def apply(%Source{} = source, %SourceURIUpdated{} = event) do
    %Source{source |
      uri: event.uri,
      date: event.date
    }
  end

  def apply(%Source{} = source, %SourceDeleted{} = _event), do: source

end
