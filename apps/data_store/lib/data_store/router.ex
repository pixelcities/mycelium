defmodule DataStore.Router do

  use Commanded.Commands.Router

  alias Core.Commands.CreateDataURI
  alias DataStore.Aggregates.Dataset

  identify(Dataset, by: :id, prefix: "datasets-")

  dispatch(
    [
      CreateDataURI
    ],
    to: Dataset
  )

end
