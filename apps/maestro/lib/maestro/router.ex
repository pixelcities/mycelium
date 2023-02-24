defmodule Maestro.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateTask,
    AssignTask,
    UnAssignTask,
    CancelTask,
    CompleteTask,
    FailTask
  }
  alias Maestro.Aggregates.{Task, TaskLifespan}

  middleware Core.Middleware.TagCommand
  middleware Core.Middleware.EnrichCommand

  identify(Task, by: :id, prefix: "tasks-")

  dispatch([ CreateTask, AssignTask, UnAssignTask, CancelTask, CompleteTask, FailTask ],
    to: Task,
    lifespan: TaskLifespan
  )

end
