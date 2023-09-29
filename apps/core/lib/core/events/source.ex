defmodule Core.Events.SourceCreated do
  use Commanded.Event,
    from: Core.Commands.CreateSource,
    with: [:date, :ds]
end

defmodule Core.Events.SourceUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateSource,
    with: [:date],
    drop: [:__metadata__]
end

defmodule Core.Events.SourceSchemaUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateSourceSchema,
    with: [:date],
    drop: [:__metadata__]
    end

defmodule Core.Events.SourceURIUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateSourceURI,
    with: [:date],
    drop: [:__metadata__]
end

defmodule Core.Events.SourceDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteSource,
    with: [:date, :uri],
    drop: [:__metadata__]
end
