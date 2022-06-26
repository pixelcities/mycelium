defmodule Core.Events.DataURICreated do
  use Commanded.Event,
    from: Core.Commands.CreateDataURI,
    with: [:uri]
    end

defmodule Core.Events.DatasetTruncated do
  use Commanded.Event,
    from: Core.Commands.TruncateDataset,
    with: [:date]
end

