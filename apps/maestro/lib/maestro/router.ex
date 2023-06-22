defmodule Maestro.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateTask,
    AssignTask,
    UnAssignTask,
    CancelTask,
    CompleteTask,
    FailTask,
    CreateMPC,
    ShareMPCPartial,
    ShareMPCResult
  }
  alias Maestro.Aggregates.{Task, TaskLifespan, MPC}

  middleware Core.Middleware.TagCommand
  middleware Core.Middleware.EnrichCommand

  identify(Task, by: :id, prefix: "tasks-")
  identify(MPC, by: :id, prefix: "mpc-")

  dispatch([ CreateTask, AssignTask, UnAssignTask, CancelTask, CompleteTask, FailTask ],
    to: Task,
    lifespan: TaskLifespan
  )

  dispatch([ CreateMPC, ShareMPCPartial, ShareMPCResult ],
    to: MPC
  )
end
