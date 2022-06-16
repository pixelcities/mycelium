defmodule Maestro.Managers.TransformerTaskProcessManager do
  @moduledoc """
  Create and manage tasks that apply transformer operations

  Whenever a transformer is created or updated, a new output collection
  needs to be generated. This process manager will listen for such events
  and ensure that tasks are scheduled that will compute the fragments of
  these collections.

  TODO: handle downstream transformers
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: __MODULE__

  @derive Jason.Encoder
  defstruct [
    :id,
    :task_id,
    :transformer,
    :wants_collection,
    :has_collection,
    :uri,
    :target
  ]

  alias Maestro.Managers.TransformerTaskProcessManager
  alias Core.Commands.{
    CreateDataURI,
    CreateCollection,
    AddTransformerTarget,
    CreateTask
  }
  alias Core.Events.{
    DataURICreated,
    CollectionCreated,
    TransformerCreated,
    TransformerInputAdded,
    TransformerWALUpdated,
    TransformerTargetAdded
  }

  # Process routing

  def interested?(%TransformerCreated{id: id}), do: {:start, id}
  def interested?(%TransformerInputAdded{id: id}), do: {:continue, id}
  def interested?(%TransformerWALUpdated{id: id}), do: {:continue, id}
  def interested?(%DataURICreated{id: id}), do: {:continue, id}
  def interested?(_event), do: false

  # Command dispatch

  @doc """
  Create unassigned tasks, and potentially a collection

  An unassigned task will be materialized and queued for future assignments when a suitable
  worker comes online.

  Note that one worker may not have enough ownership to create the full output collection.
  Task assignment will instead take care of duplicating the task as many times as needed
  so that all fragments make up a full collection.

  An empty collection needs to be created when this is the last transformer in a group, so that
  each worker can add their fragment to the right dataset. We first request and wait for the
  dataset uri, after which the collection can be created.
  """
  def handle(%TransformerTaskProcessManager{wants_collection: true, has_collection: false, uri: nil} = pm, %TransformerWALUpdated{wal: wal} = _event) do
    %CreateDataURI{
      id: pm.id,
      workspace: pm.transformer.workspace
    }
  end

  def handle(%TransformerTaskProcessManager{wants_collection: true, has_collection: false} = pm, %DataURICreated{uri: uri} = _event) do
    collection_id = UUID.uuid4()
    in_collection = MetaStore.get_collection!(hd(pm.transformer.collections))

    [
      %CreateCollection{
        id: collection_id,
        workspace: pm.transformer.workspace,
        type: "collection",
        uri: uri,
        schema: nil,
        position: [hd(pm.transformer.position) + 200.0, Enum.at(pm.transformer.position, 1)],
        color: pm.transformer.color,
        is_ready: false
      },
      %AddTransformerTarget{
        id: pm.id,
        workspace: pm.transformer.workspace,
        target: collection_id
      },
      %CreateTask{
        id: UUID.uuid4(),
        type: "transformer",
        task: %{
          "instruction" => "compute_fragment",
          "transformer_id" => pm.id,
          "uri" => uri,
          "wal" => pm.transformer.wal
        },
        fragments: in_collection.schema.column_order
      }
    ]
  end


  # State mutators

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerCreated{} = event) do
    %TransformerTaskProcessManager{pm |
      id: event.id,
      transformer: event,
      wants_collection: true, # Hardcoded for now
      has_collection: false
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerInputAdded{} = event) do
    %TransformerTaskProcessManager{pm |
      transformer: Map.put(pm.transformer, :collections, [event.collection])
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerWALUpdated{} = event) do
    %TransformerTaskProcessManager{pm |
      transformer: Map.put(pm.transformer, :wal, event.wal)
    }
  end

  def apply(%TransformerTaskProcessManager{uri: nil} = pm, %DataURICreated{} = event) do
    %TransformerTaskProcessManager{pm |
      uri: event.uri
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerTargetAdded{} = event) do
    %TransformerTaskProcessManager{pm |
      has_collection: true,
      target: event.target
    }
  end

end
