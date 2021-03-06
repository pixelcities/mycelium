defmodule Core.Events.SourceCreated do
  use Commanded.Event,
    from: Core.Commands.CreateSource,
    with: [:date]
end

defmodule Core.Events.SourceUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateSource,
    with: [:date]
end
