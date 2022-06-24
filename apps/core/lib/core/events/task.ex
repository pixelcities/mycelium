defmodule Core.Events.TaskCreated do
  use Commanded.Event,
    from: Core.Commands.CreateTask,
    with: [:date]
end

defmodule Core.Events.TaskAssigned do
  use Commanded.Event,
    from: Core.Commands.AssignTask,
    with: [:date]
end

defmodule Core.Events.TaskUnAssigned do
  use Commanded.Event,
    from: Core.Commands.UnAssignTask,
    with: [:date]
end

defmodule Core.Events.TaskCompleted do
  use Commanded.Event,
    from: Core.Commands.CompleteTask,
    with: [:date]
end

