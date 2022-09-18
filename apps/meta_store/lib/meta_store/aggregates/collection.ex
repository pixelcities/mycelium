defmodule MetaStore.Aggregates.CollectionLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.CollectionDeleted

  def after_event(%CollectionDeleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

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
  alias Core.Commands.{CreateCollection, UpdateCollection, UpdateCollectionSchema, SetCollectionPosition, SetCollectionIsReady, AddCollectionTarget, RemoveCollectionTarget, DeleteCollection}
  alias Core.Events.{CollectionCreated, CollectionUpdated, CollectionSchemaUpdated, CollectionPositionSet, CollectionIsReadySet, CollectionTargetAdded, CollectionTargetRemoved, CollectionDeleted}

  def execute(%Collection{id: nil}, %CreateCollection{} = collection) do
    CollectionCreated.new(collection, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = collection, %UpdateCollection{} = update)
    when collection.workspace == update.workspace
  do
    CollectionUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = _collection, %UpdateCollectionSchema{} = update) do
    CollectionSchemaUpdated.new(update, date: NaiveDateTime.utc_now())
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

  def execute(%Collection{} = collection, %DeleteCollection{} = command) do
    CollectionDeleted.new(command,
      uri: collection.uri,
      date: NaiveDateTime.utc_now()
    )
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
      targets: Enum.filter(collection.targets, fn target -> target == event.target end),
      date: event.date
    }
  end

end
