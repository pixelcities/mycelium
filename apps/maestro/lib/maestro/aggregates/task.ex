defmodule Maestro.Aggregates.TaskLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.TaskCompleted

  def after_event(%TaskCompleted{is_completed: is_completed}) when is_completed, do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule Maestro.Aggregates.Task do
  defstruct id: nil,
            type: nil,
            task: nil,
            worker: nil,
            fragments: [],
            completed_fragments: [],
            is_completed: false

  alias Maestro.Aggregates.Task
  alias Core.Commands.{CreateTask, AssignTask, CompleteTask}
  alias Core.Events.{TaskCreated, TaskAssigned, TaskCompleted}

  @doc """
  Create a new (unassigned) task
  """
  def execute(%Task{id: nil}, %CreateTask{} = command) do
    TaskCreated.new(command, date: NaiveDateTime.utc_now())
  end

  def execute(%Task{} = task, %AssignTask{} = command) do
    event = task
      |> Map.merge(command, fn _k, v1, v2 -> v1 || v2 end)
      |> Map.put(:fragments, command.fragments)

    TaskAssigned.new(event, date: NaiveDateTime.utc_now())
  end

  def execute(%Task{} = task, %CompleteTask{} = command)
    when command.is_completed == true
  do
    # Check if the task is truly complete, as it is not when there are still uncompleted
    # fragments. When there are no fragments it is automatically completed.
    if length(task.fragments) > 0 do
      total_fragments = Enum.concat(task.completed_fragments, command.fragments) |> Enum.uniq

      if Enum.sort(total_fragments) == Enum.sort(task.fragments) do
        TaskCompleted.new(command, date: NaiveDateTime.utc_now())
      else
        TaskCompleted.new(Map.put(command, :is_completed, false), date: NaiveDateTime.utc_now())
      end
    else
      TaskCompleted.new(command, date: NaiveDateTime.utc_now())
    end
  end


  # State mutators

  def apply(%Task{} = task, %TaskCreated{} = event) do
    %Task{task |
      id: event.id,
      type: event.type,
      task: event.task,
      worker: event.worker,
      fragments: event.fragments
    }
  end

  def apply(%Task{} = task, %TaskAssigned{} = event) do
    %Task{task |
      worker: event.worker
    }
  end

  def apply(%Task{} = task, %TaskCompleted{} = event) do
    %Task{task |
      completed_fragments: Enum.concat(task.completed_fragments, event.fragments) |> Enum.uniq,
      is_completed: event.is_completed
    }
  end

end
