defmodule Core.Events.MetadataCreated do
  use Commanded.Event,
    from: Core.Commands.CreateMetadata,
    with: [:date]
end

defmodule Core.Events.MetadataUpdated do
  use Commanded.Event,
    from: Core.Commands.UpdateMetadata,
    with: [:date]
end

