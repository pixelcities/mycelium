defmodule Core.Events.UserCreated do
  use Commanded.Event,
    from: Core.Commands.CreateUser,
    with: [:date]
end

defmodule Core.Events.UserUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateUser,
    with: [:date]
end

