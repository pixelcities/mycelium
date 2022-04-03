defmodule Core.Events.DataURICreated do
  use Commanded.Event,
    from: Core.Commands.CreateDataURI,
    with: [:uri]
end

