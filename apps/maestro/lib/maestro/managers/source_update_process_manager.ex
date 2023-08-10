defmodule Maestro.Managers.SourceUpdateProcessManager do
  @moduledoc """
  Updates source collection, and triggers any downstream tasks
  """

  use Commanded.ProcessManagers.ProcessManager,
    name: __MODULE__,
    consistency: :strong

  @derive Jason.Encoder
  defstruct [
    :id,
    :collection,
    :created_tasks
  ]

  import Maestro.Utils

  alias Maestro.Managers.SourceUpdateProcessManager
  alias Core.Commands.{
    UpdateCollectionURI,
    CreateTask,
    CancelTask
  }
  alias Core.Events.{
    CollectionCreated,
    CollectionDeleted,
    SourceURIUpdated,
    TaskCreated,
    TaskFailed,
    TaskCancelled,
    TaskCompleted
  }


  ## Process routing

  def interested?(%CollectionCreated{id: id, type: "source"}), do: {:start, id}
  # Not interested in source update events when there are no source collections (skipped in error handler)
  def interested?(%SourceURIUpdated{id: id}), do: {:continue!, id}
  def interested?(%TaskCreated{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%TaskCompleted{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%TaskCancelled{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%TaskFailed{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%CollectionDeleted{id: id}), do: {:stop, id}
  def interested?(_event), do: false


  ## Command dispatch

  def handle(%SourceUpdateProcessManager{id: id} = pm, %SourceURIUpdated{uri: uri} = _event) do
    Enum.map(pm.created_tasks || [], fn task_id ->
      %CancelTask{
        id: task_id,
        is_cancelled: true
      }
    end)
      ++
        [
          %UpdateCollectionURI{
            id: pm.collection.id,
            workspace: pm.collection.workspace,
            uri: uri
          }
        ]
      ++
    Enum.map(MetaStore.get_transformers_by_collection(id, tenant: pm.collection.ds), fn t ->
      identifiers = get_transformer_identifiers(t)

      %CreateTask{
        id: UUID.uuid4(),
        type: "transformer",
        task: %{
          "instruction" => "update_artifacts",
          "transformer_id" => t.id,
          "wal" => t.wal
        },
        fragments: Enum.map(identifiers, fn x -> Map.get(x, "id") end)
      }
    end)
  end


  # Error handlers

  def error({:error, {:continue!, :process_not_started}}, _failed_command, _context) do
    :skip
  end

  def error({:error, _failure}, _failed_command, %{context: %{failures: failures}})
    when failures >= 2
  do
    :skip
  end

  def error({:error, _failure}, _failed_command, %{context: context}) do
    context = Map.update(context, :failures, 1, fn failures -> failures + 1 end)

    {:retry, context}
  end


  ## State mutators

  def apply(%SourceUpdateProcessManager{} = pm, %CollectionCreated{} = event) do
    %SourceUpdateProcessManager{pm |
      id: event.id,
      collection: event
    }
  end

  def apply(%SourceUpdateProcessManager{} = pm, %TaskCreated{} = event) do
    %SourceUpdateProcessManager{pm |
      created_tasks: Enum.concat(pm.created_tasks || [], [event.id]) |> Enum.uniq()
    }
  end

  def apply(%SourceUpdateProcessManager{} = pm, %TaskCancelled{} = event) do
    %SourceUpdateProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks || [], fn task_id -> task_id != event.id end)
    }
  end

  def apply(%SourceUpdateProcessManager{} = pm, %TaskCompleted{} = event) do
    %SourceUpdateProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks || [], fn task_id -> task_id != event.id end)
    }
  end

  def apply(%SourceUpdateProcessManager{} = pm, %TaskFailed{} = event) do
    %SourceUpdateProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks || [], fn task_id -> task_id != event.id end)
    }
  end

  def apply(%SourceUpdateProcessManager{} = pm, %CollectionDeleted{} = _event), do: pm

end
