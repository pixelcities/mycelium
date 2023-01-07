defmodule Maestro.Managers.WidgetTaskProcessManager do
  use Commanded.ProcessManagers.ProcessManager,
    name: __MODULE__,
    consistency: :strong

  @derive Jason.Encoder
  defstruct [
    :id,
    :widget,
    :created_tasks,
    :is_deleted
  ]

  alias Maestro.Managers.WidgetTaskProcessManager
  alias Core.Commands.{
    SetWidgetIsReady
  }
  alias Core.Events.{
    WidgetCreated,
    WidgetDeleted,
    TaskCreated,
    TaskCancelled,
    TaskCompleted
  }

  # Process routing

  def interested?(%WidgetCreated{id: id}), do: {:start, id}
  def interested?(%TaskCreated{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%TaskCancelled{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%TaskCompleted{causation_id: id}) when id != nil, do: {:continue, id}
  def interested?(%WidgetDeleted{id: id}), do: {:stop, id}
  def interested?(_event), do: false

  # Command dispatch

  def handle(%WidgetTaskProcessManager{} = pm, %TaskCompleted{is_completed: true} = _event) do
    [
      %SetWidgetIsReady{
        id: pm.id,
        workspace: pm.widget.workspace,
        is_ready: true
      }
    ]
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

  def apply(%WidgetTaskProcessManager{} = pm, %WidgetCreated{} = event) do
    %WidgetTaskProcessManager{pm |
      id: event.id,
      widget: event
    }
  end

  def apply(%WidgetTaskProcessManager{} = pm, %TaskCreated{} = event) do
    %WidgetTaskProcessManager{pm |
      created_tasks: Enum.concat(pm.created_tasks || [], [event.id]) |> Enum.uniq()
    }
  end

  def apply(%WidgetTaskProcessManager{} = pm, %TaskCancelled{} = event) do
    %WidgetTaskProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks, fn task_id -> task_id != event.id end)
    }
  end

  def apply(%WidgetTaskProcessManager{} = pm, %TaskCompleted{} = event) do
    %WidgetTaskProcessManager{pm |
      created_tasks: Enum.filter(pm.created_tasks, fn task_id -> task_id != event.id end)
    }
  end

  def apply(%WidgetTaskProcessManager{} = pm, %WidgetDeleted{} = _event) do
    %WidgetTaskProcessManager{pm |
      is_deleted: true
    }
  end

end
