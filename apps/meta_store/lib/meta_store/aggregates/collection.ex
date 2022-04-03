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
  alias Core.Commands.{CreateCollection, UpdateCollection, SetCollectionPosition, AddCollectionTarget}
  alias Core.Events.{CollectionCreated, CollectionUpdated, CollectionPositionSet, CollectionTargetAdded}

  @doc """
  Create a new collection
  """
  def execute(%Collection{id: nil}, %CreateCollection{} = collection) do
    CollectionCreated.new(collection, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = collection, %UpdateCollection{} = update)
    when collection.workspace == update.workspace
  do
    CollectionUpdated.new(update, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = _collection, %SetCollectionPosition{} = position) do
    CollectionPositionSet.new(position, date: NaiveDateTime.utc_now())
  end

  def execute(%Collection{} = collection, %AddCollectionTarget{} = command) do
    CollectionTargetAdded.new(%{
      id: collection.id,
      workspace: collection.workspace,
      target: command.target,
      date: NaiveDateTime.utc_now()
    })
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

  def apply(%Collection{} = collection, %CollectionPositionSet{} = event) do
    %Collection{collection |
      position: event.position,
      date: event.date
    }
  end

  def apply(%Collection{} = collection, %CollectionTargetAdded{} = event) do
    %Collection{collection |
      targets: collection.targets ++ [event.target],
      date: event.date
    }
  end

end
