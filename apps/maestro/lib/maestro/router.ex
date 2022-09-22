defmodule Maestro.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateTask,
    AssignTask,
    UnAssignTask,
    CancelTask,
    CompleteTask
  }
  alias Maestro.Aggregates.{Task, TaskLifespan}

  middleware Core.Middleware.TagCommand
  middleware Core.Middleware.EnrichCommand

  identify(Task, by: :id, prefix: "tasks-")

  dispatch([ CreateTask, AssignTask, UnAssignTask, CancelTask, CompleteTask ],
    to: Task,
    lifespan: TaskLifespan
  )

end
