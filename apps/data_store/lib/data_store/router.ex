defmodule DataStore.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{
    CreateDataURI,
    RequestTruncateDataset,
    TruncateDataset,
    RequestDeleteDataset,
    DeleteDataset
  }
  alias DataStore.Aggregates.{
    Dataset,
    DatasetLifespan
  }

  middleware Core.Middleware.TagCommand

  identify(Dataset, by: :id, prefix: "datasets-")

  dispatch(
    [
      CreateDataURI,
      RequestTruncateDataset,
      TruncateDataset,
      RequestDeleteDataset,
      DeleteDataset
    ],
    to: Dataset,
    lifespan: DatasetLifespan
  )

end
