defmodule DataStore.Router do

  use Commanded.Commands.Router

  alias Core.Commands.{CreateDataURI, TruncateDataset}
  alias DataStore.Aggregates.Dataset

  identify(Dataset, by: :id, prefix: "datasets-")

  dispatch(
    [
      CreateDataURI,
      TruncateDataset
    ],
    to: Dataset
  )

end
