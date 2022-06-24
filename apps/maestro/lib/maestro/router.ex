defmodule Maestro.Router do

  use Commanded.Commands.Router

  alias Core.Middleware.EnrichCommand
  alias Core.Commands.{
    CreateTask,
    AssignTask,
    UnAssignTask,
    CompleteTask
  }
  alias Maestro.Aggregates.{Task, TaskLifespan}

  middleware EnrichCommand

  identify(Task, by: :id, prefix: "tasks-")

  dispatch([ CreateTask, AssignTask, UnAssignTask, CompleteTask ],
    to: Task,
    lifespan: TaskLifespan
  )

end
