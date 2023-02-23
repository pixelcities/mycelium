defmodule Maestro.Aggregates.TaskLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.{TaskCancelled, TaskCompleted}

  def after_event(%TaskCancelled{}), do: :stop
  def after_event(%TaskCompleted{is_completed: is_completed}) when is_completed, do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule Maestro.Aggregates.Task do
  defstruct id: nil,
            causation_id: nil,
            type: nil,
            task: nil,
            worker: nil,
            fragments: [],
            completed_fragments: [],
            metadata: %{},
            ttl: 300,
            is_cancelled: false,
            is_completed: false,
            is_assigned: false,
            assigned_at: nil

  alias Maestro.Aggregates.Task
  alias Core.Commands.{CreateTask, AssignTask, UnAssignTask, CancelTask, CompleteTask}
  alias Core.Events.{TaskCreated, TaskAssigned, TaskUnAssigned, TaskCancelled, TaskCompleted}


  def execute(%Task{id: nil}, %CreateTask{} = command) do
    TaskCreated.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Task{} = task, %AssignTask{} = command) do
    if task.is_assigned == false || task_expired?(task.assigned_at, task.ttl) do
      # Fragments are guaranteed to be owned by the middleware enrichment, but maybe
      # some fragments are already completed so we can deduct those.
      fragments = Enum.filter(command.fragments, fn fragment -> fragment not in task.completed_fragments end)

      # Maybe this worker has no uncompleted fragments left, which is
      # essentially a noop.
      if length(task.fragments) > 0 and length(fragments) == 0 do
        {:error, :task_noop}

      else
        event = task
          |> Map.merge(command, fn _k, v1, v2 -> v1 || v2 end)
          |> Map.put(:fragments, fragments)

        TaskAssigned.new(event, date: NaiveDateTime.utc_now())
      end
    else
      {:error, :task_already_assigned}
    end
  end

  # def execute(%Task{} = task, %UnAssignTask{} = _) when task.is_assigned == false, do: {:error, :task_already_unassigned}
  def execute(%Task{} = task, %UnAssignTask{} = _) when length(task.fragments) == 0 do
    # Special case. Tasks without fragments are oneshots, so we might as well close them.
    TaskCancelled.new(%{
      id: task.id,
      is_cancelled: true,
      date: NaiveDateTime.utc_now()
    })
  end
  def execute(%Task{} = _task, %UnAssignTask{} = command) do
    TaskUnAssigned.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Task{} = task, %CancelTask{} = command) do
    TaskCancelled.new(command, causation_id: task.causation_id, date: NaiveDateTime.utc_now())
  end

  def execute(%Task{} = task, %CompleteTask{} = command) when command.worker != task.worker, do: {:error, :task_not_owned}
  def execute(%Task{} = task, %CompleteTask{} = command)
    when command.is_completed == true and command.worker == task.worker
  do
    # Check if the task is truly complete, as it is not when there are still uncompleted
    # fragments. When there are no fragments it is automatically completed.
    is_completed = if length(task.fragments) > 0 do
      total_fragments = Enum.concat(task.completed_fragments, command.fragments) |> Enum.uniq

      Enum.all?(task.fragments, fn f -> f in total_fragments end)
    else
      true
    end

    TaskCompleted.new(Map.put(command, :is_completed, is_completed), causation_id: task.causation_id, date: NaiveDateTime.utc_now())
  end

  defp task_expired?(%NaiveDateTime{} = assigned_at, ttl) do
    if assigned_at == nil, do: false, else: NaiveDateTime.compare(NaiveDateTime.add(NaiveDateTime.utc_now(), -(ttl || 0)), assigned_at) == :gt
  end
  defp task_expired?(assigned_at, ttl), do: task_expired?(NaiveDateTime.from_iso8601!(assigned_at), ttl)

  # State mutators

  def apply(%Task{} = task, %TaskCreated{} = event) do
    %Task{task |
      id: event.id,
      causation_id: event.causation_id,
      type: event.type,
      task: event.task,
      worker: event.worker,
      fragments: event.fragments,
      metadata: event.metadata,
      ttl: event.ttl
    }
  end

  def apply(%Task{} = task, %TaskAssigned{} = event) do
    %Task{task |
      worker: event.worker,
      is_assigned: true,
      assigned_at: event.date
    }
  end

  def apply(%Task{} = task, %TaskUnAssigned{} = _event) do
    %Task{task |
      worker: nil,
      is_assigned: false
    }
  end

  def apply(%Task{} = task, %TaskCancelled{} = _event) do
    %Task{task |
      is_cancelled: true
    }
  end

  def apply(%Task{} = task, %TaskCompleted{} = event) do
    %Task{task |
      completed_fragments: Enum.concat(task.completed_fragments, event.fragments) |> Enum.uniq,
      metadata: event.metadata,
      is_completed: event.is_completed,
      worker: nil,
      is_assigned: false
    }
  end

end
