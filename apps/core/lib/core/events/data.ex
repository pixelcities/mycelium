defmodule Core.Events.DataURICreated do
  use Commanded.Event,
    from: Core.Commands.CreateDataURI,
    with: [:uri]
end

defmodule Core.Events.TruncateDatasetRequested do
  use Commanded.Event,
    from: Core.Commands.RequestTruncateDataset,
    with: [:uri, :date]
end

defmodule Core.Events.DatasetTruncated do
  use Commanded.Event,
    from: Core.Commands.TruncateDataset,
    with: [:date]
end

defmodule Core.Events.DeleteDatasetRequested do
  use Commanded.Event,
    from: Core.Commands.RequestDeleteDataset,
    with: [:uri, :date]
end

defmodule Core.Events.DatasetDeleted do
  use Commanded.Event,
    from: Core.Commands.DeleteDataset,
    with: [:date]
end

