defmodule DataStore.Aggregates.Dataset do
  defstruct id: nil,
            workspace: nil,
            uri: nil

  alias DataStore.Aggregates.Dataset
  alias Core.Commands.{CreateDataURI, TruncateDataset}
  alias Core.Events.{DataURICreated, DatasetTruncated}

  @doc """
  Generate a new data URI and associate a session
  """
  def execute(%Dataset{id: nil}, %CreateDataURI{} = cmd) do
    data_space = "ds1"
    workspace = cmd.workspace
    dataset_id = UUID.uuid4()

    DataURICreated.new(cmd,
      uri: "s3://pxc-collection-store/#{data_space}/#{workspace}/#{dataset_id}"
    )
  end

  def execute(%Dataset{uri: uri}, %TruncateDataset{} = cmd) do
    # TODO: Release truncate requested event and have PM handle the side effect
    IO.puts("Truncate for dataset #{uri} requested")
  end

  # State mutators

  def apply(%Dataset{} = dataset, %DataURICreated{} = event) do
    %Dataset{dataset |
      id: event.id,
      workspace: event.workspace,
      uri: event.uri
    }
  end
end
