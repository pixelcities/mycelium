defmodule MetaStore.Aggregates.Collection do
  defstruct id: nil,
            workspace: nil,
            type: nil,
            uri: nil,
            schema: nil,
            targets: [],
            position: [],
            color: "#000000",
            is_ready: false,
            date: nil

  alias MetaStore.Aggregates.Collection
  alias Core.Commands.{
    CreateCollection,
    UpdateCollection,
    UpdateCollectionURI,
    UpdateCollectionSchema,
    SetCollectionColor,
    SetCollectionPosition,
    SetCollectionIsReady,
    AddCollectionTarget,
    RemoveCollectionTarget,
    DeleteCollection
  }
  alias Core.Events.{
    CollectionCreated,
    CollectionUpdated,
    CollectionSchemaUpdated,
    CollectionColorSet,
    CollectionPositionSet,
    CollectionIsReadySet,
    CollectionTargetAdded,
    CollectionTargetRemoved,
    CollectionDeleted
  }

  def execute(%Collection{id: nil}, %CreateCollection{} = collection) do
    CollectionCreated.new(collection, date: NaiveDateTime.utc_now())
  end
  def execute(%Collection{}, %CreateCollection{}), do: {:error, :collection_already_exists}

  def execute(%Collection{} = collection, %UpdateCollectionURI{uri: uri}) do
    CollectionUpdated.new(collection,
      uri: uri,
      date: NaiveDateTime.utc_now()
    )
  end

  def execute(%Collection{} = collection, %UpdateCollection{__metadata__: %{user_id: user_id}} = update)
    when collection.workspace == update.workspace and hd(collection.uri) == hd(update.uri)
  do
    if authorized?(user_id, collection.schema) && valid_shares?(user_id, collection.schema, update.schema) do
      CollectionUpdated.new(update, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end

  def execute(%Collection{} = collection, %UpdateCollectionSchema{__metadata__: %{user_id: user_id, is_internal: is_internal}} = update) do
    if is_internal || (authorized?(user_id, collection.schema) && valid_shares?(user_id, collection.schema, update.schema)) do
      CollectionSchemaUpdated.new(update, date: NaiveDateTime.utc_now())
    else
      {:error, :unauthorized}
    end
  end

  def execute(%Collection{} = _collection, %SetCollectionColor{} = command) do
    CollectionColorSet.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = _collection, %SetCollectionPosition{} = position) do
    CollectionPositionSet.new(position, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = _collection, %SetCollectionIsReady{} = command) do
    CollectionIsReadySet.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = collection, %AddCollectionTarget{} = command) do
    CollectionTargetAdded.new(%{
      id: collection.id,
      workspace: collection.workspace,
      target: command.target,
      date: NaiveDateTime.utc_now()
    })
  end

  def execute(%Collection{} = collection, %RemoveCollectionTarget{} = command) do
    if Enum.any?(Enum.map(collection.targets, fn target -> target == command.target end)) do
      CollectionTargetRemoved.new(command, date: NaiveDateTime.utc_now())
    else
      {:error, :no_such_target}
    end
  end

  def execute(%Collection{} = collection, %DeleteCollection{__metadata__: %{user_id: user_id, is_admin: is_admin}} = command) do
    if is_admin || authorized?(user_id, collection.schema) do
      CollectionDeleted.new(command,
        type: collection.type,
        uri: collection.uri,
        date: NaiveDateTime.utc_now()
      )
    end
  end

  # TODO: Enforce locking behaviour
  defp authorized?(user_id, schema) do
    Enum.any?(schema.shares || [], fn share ->
      share.principal == user_id
    end)
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

  def apply(%Collection{} = collection, %CollectionCreated{} = created) do
    %Collection{collection |
      id: created.id,
      workspace: created.workspace,
      uri: created.uri,
      type: created.type,
      schema: created.schema,
      targets: created.targets,
      position: created.position,
      color: created.color,
      is_ready: created.is_ready,
      date: created.date
    }
  end

  def apply(%Collection{} = collection, %CollectionUpdated{} = updated) do
    %Collection{collection |
      is_ready: updated.is_ready,
      date: updated.date
    }
  end

  def apply(%Collection{} = collection, %CollectionSchemaUpdated{} = updated) do
    %Collection{collection |
      schema: updated.schema,
      date: updated.date
    }
  end

  def apply(%Collection{} = collection, %CollectionColorSet{} = event) do
    %Collection{collection |
      color: event.color,
      date: event.date
    }
  end

  def apply(%Collection{} = collection, %CollectionPositionSet{} = event) do
    %Collection{collection |
      position: event.position,
      date: event.date
    }
  end

  def apply(%Collection{} = collection, %CollectionIsReadySet{} = event) do
    %Collection{collection |
      is_ready: event.is_ready,
      date: event.date
    }
  end

  def apply(%Collection{} = collection, %CollectionTargetAdded{} = event) do
    %Collection{collection |
      targets: collection.targets ++ [event.target],
      date: event.date
    }
  end

  def apply(%Collection{} = collection, %CollectionTargetRemoved{} = event) do
    %Collection{collection |
      targets: Enum.reject(collection.targets, fn target -> target == event.target end),
      date: event.date
    }
  end

  def apply(%Collection{} = _collection, %CollectionDeleted{} = _event), do: __MODULE__.__struct__

end
