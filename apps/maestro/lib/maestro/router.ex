defmodule Maestro.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateTask,
    AssignTask,
    CompleteTask
  }
  alias Maestro.Aggregates.{Task, TaskLifespan}

  identify(Task, by: :id, prefix: "tasks-")

  dispatch([ CreateTask, AssignTask, CompleteTask ],
    to: Task,
    lifespan: TaskLifespan
  )

end
