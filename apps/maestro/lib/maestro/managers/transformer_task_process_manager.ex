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
    name: __MODULE__,
    consistency: :strong

  @derive Jason.Encoder
  defstruct [
    :id,
    :transformer,
    :wants_collection,
    :has_collection,
    :uri,
    :target,
    :created_tasks,
    :is_deleted
  ]

  alias Maestro.Managers.TransformerTaskProcessManager
  alias Core.Commands.{
    CreateDataURI,
    RequestTruncateDataset,
    CreateCollection,
    SetCollectionIsReady,
    AddTransformerTarget,
    CreateTask,
    CancelTask
  }
  alias Core.Events.{
    DataURICreated,
    DatasetTruncated,
    TaskCreated,
    TaskCancelled,
    TaskCompleted,
    TransformerCreated,
    TransformerInputAdded,
    TransformerWALUpdated,
    TransformerTargetAdded,
    TransformerDeleted
  }

  # Process routing

  def interested?(%TransformerCreated{id: id}), do: {:start, id}
  def interested?(%TransformerInputAdded{id: id}), do: {:continue, id}
  def interested?(%TransformerTargetAdded{id: id}), do: {:continue, id}
  def interested?(%TransformerWALUpdated{id: id}), do: {:continue, id}
  def interested?(%TaskCreated{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%TaskCompleted{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%DataURICreated{id: id}), do: {:continue, id}
  def interested?(%DatasetTruncated{id: id}), do: {:continue, id}
  def interested?(%TransformerDeleted{id: id}), do: {:continue, id}
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

  def handle(%TransformerTaskProcessManager{wants_collection: true, has_collection: false, uri: nil} = pm, %TransformerWALUpdated{wal: _wal} = _event) do
    %CreateDataURI{
      id: pm.id,
      workspace: pm.transformer.workspace
    }
  end

  def handle(%TransformerTaskProcessManager{has_collection: true} = pm, %TransformerWALUpdated{wal: _wal} = _event) do
    Enum.map(pm.created_tasks, fn task_id ->
      %CancelTask{
        id: task_id,
        is_cancelled: true
      }
    end)
      ++
    [
      %SetCollectionIsReady{
        id: pm.target,
        workspace: pm.transformer.workspace,
        is_ready: false
      },
      %RequestTruncateDataset{
        id: pm.id
      }
    ]
  end

  # TODO: Handle bad fragments that are the result of a failed task. Because the truncation has already happened,
  # but a task may be assigned multiple times (retries, multiple shares, etc) a bad upload from the client side
  # will corrupt the dataset.
  def handle(%TransformerTaskProcessManager{has_collection: true, target: _target} = pm, %DatasetTruncated{} = _event) do
    in_collections = Enum.map(pm.transformer.collections, fn collection_id -> MetaStore.get_collection!(collection_id, tenant: pm.transformer.ds) end)
    collection = MetaStore.get_collection!(pm.target, tenant: pm.transformer.ds)

    if (collection != nil) and (collection.schema != nil) do
      schema_id = MetaStore.get_collection!(pm.target, tenant: pm.transformer.ds).schema.id
      schema = MetaStore.get_schema!(schema_id, tenant: pm.transformer.ds)

      %CreateTask{
        id: UUID.uuid4(),
        causation_id: pm.id,
        type: "transformer",
        task: %{
          "instruction" => "compute_fragment",
          "collection_id" => pm.target,
          "transformer_id" => pm.id,
          "uri" => pm.uri,
          "wal" => pm.transformer.wal
        },
        fragments: Enum.flat_map(in_collections, fn collection -> collection.schema.column_order end),
        metadata: %{
          "schema" => schema
        }
      }
    else
      {:error, :bad_state}
    end
  end

  def handle(%TransformerTaskProcessManager{wants_collection: true, has_collection: false} = pm, %DataURICreated{uri: uri} = _event) do
    collection_id = UUID.uuid4()
    in_collections = Enum.map(pm.transformer.collections, fn collection_id -> MetaStore.get_collection!(collection_id, tenant: pm.transformer.ds) end)
    collection_color = if length(in_collections) == 1, do: hd(in_collections).color, else: "#FFFFFF"

    [
      %CreateCollection{
        id: collection_id,
        workspace: pm.transformer.workspace,
        type: "collection",
        uri: uri,
        schema: nil,
        position: [hd(pm.transformer.position) + 200.0, Enum.at(pm.transformer.position, 1)],
        color: collection_color,
        is_ready: false
      },
      %AddTransformerTarget{
        id: pm.id,
        workspace: pm.transformer.workspace,
        target: collection_id
      },
      %CreateTask{
        id: UUID.uuid4(),
        causation_id: pm.id,
        type: "transformer",
        task: %{
          "instruction" => "compute_fragment",
          "collection_id" => collection_id,
          "transformer_id" => pm.id,
          "uri" => uri,
          "wal" => pm.transformer.wal
        },
        fragments: Enum.flat_map(in_collections, fn collection -> collection.schema.column_order end),
        metadata: %{}
      }
    ]
  end

  def handle(%TransformerTaskProcessManager{has_collection: true} = pm, %TaskCompleted{is_completed: true} = _event) do
    %SetCollectionIsReady{
      id: pm.target,
      workspace: pm.transformer.workspace,
      is_ready: true
    }
  end

  # TODO: Handle shutdown when there are no more open tasks (currently handled by after_command/2)
  def handle(%TransformerTaskProcessManager{has_collection: true} = pm, %TransformerDeleted{} = _event) do
    Enum.map(pm.created_tasks, fn task_id ->
      %CancelTask{
        id: task_id,
        is_cancelled: true
      }
    end)
  end

  def after_command(%TransformerTaskProcessManager{is_deleted: true} = _pm, %CancelTask{}) do
    :stop
  end


  # Error handlers

  def error({:error, _failure}, _failed_command, %{context: %{failures: failures}})
    when failures >= 2
  do
    :skip
  end

  def error({:error, _failure}, _failed_command, %{context: context}) do
    context = Map.update(context, :failures, 1, fn failures -> failures + 1 end)

    {:retry, context}
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
      transformer: Map.put(pm.transformer, :collections, pm.transformer.collections ++ [event.collection])
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

  def apply(%TransformerTaskProcessManager{} = pm, %TaskCreated{} = event) do
    %TransformerTaskProcessManager{pm |
      created_tasks: Enum.concat(pm.created_tasks || [], [event.id]) |> Enum.uniq()
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TaskCancelled{} = event) do
    %TransformerTaskProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks, fn task_id -> task_id != event.id end)
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TaskCompleted{} = event) do
    %TransformerTaskProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks, fn task_id -> task_id != event.id end)
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerTargetAdded{} = event) do
    %TransformerTaskProcessManager{pm |
      has_collection: true,
      target: event.target
    }
  end

  def apply(%TransformerTaskProcessManager{} = pm, %TransformerDeleted{} = _event) do
    %TransformerTaskProcessManager{pm |
      is_deleted: true
    }
  end

end
