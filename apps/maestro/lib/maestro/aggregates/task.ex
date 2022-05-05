defmodule Maestro.Aggregates.TaskLifespan do
  @behaviour Commanded.Aggregates.AggregateLifespan

  alias Core.Events.TaskCompleted

  def after_event(%TaskCompleted{}), do: :stop
  def after_event(_event), do: :infinity
  def after_command(_command), do: :infinity
  def after_error(_error), do: :stop
end

defmodule Maestro.Aggregates.Task do
  defstruct id: nil,
            type: nil,
            task: nil,
            worker: nil,
            is_complete: false

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
    event = Map.put(task, :worker, command.worker)
    TaskAssigned.new(event, date: NaiveDateTime.utc_now())
  end

  def execute(%Task{}, %CompleteTask{} = command)
    when command.is_complete == true
  do
    TaskCompleted.new(command, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Task{} = task, %TaskCreated{} = event) do
    %Task{task |
      id: event.id,
      type: event.type,
      task: event.task,
      worker: event.worker
    }
  end

  def apply(%Task{} = task, %TaskAssigned{} = event) do
    %Task{task |
      worker: event.worker
    }
  end

  def apply(%Task{} = task, %TaskCompleted{} = _event) do
    %Task{task |
      is_complete: true
    }
  end

end
