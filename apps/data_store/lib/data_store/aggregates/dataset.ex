defmodule DataStore.Aggregates.Dataset do
  defstruct id: nil,
            workspace: nil,
            uri: nil,
            type: nil,
            version: 1,
            date: nil

  alias DataStore.Aggregates.Dataset
  alias Core.Commands.{CreateDataURI, RequestTruncateDataset, TruncateDataset, RequestDeleteDataset, DeleteDataset}
  alias Core.Events.{DataURICreated, TruncateDatasetRequested, DatasetTruncated, DeleteDatasetRequested, DatasetDeleted}
  alias Core.Integrity

  @doc """
  Generate and track data URIs

  There can be any number of fragments stored in a dataset. A truncate request
  will be handled by a process manager that will simply delete all the child objects.

  A delete request will also delete the `/dataset_id` path itself.
  """

  def execute(%Dataset{uri: nil, version: version}, %CreateDataURI{} = cmd) do
    data_space = cmd.ds

    if data_space do
      workspace = cmd.workspace
      type = cmd.type
      dataset_id = UUID.uuid4()

      uri = "s3://pxc-collection-store/#{data_space}/#{workspace}/#{type}/#{dataset_id}/v#{version}"
      tag = Integrity.sign(uri)

      DataURICreated.new(cmd,
        uri: uri,
        tag: tag
      )
    else
      {:error, :invalid_ds}
    end
  end

  def execute(%Dataset{uri: old_uri, version: version}, %CreateDataURI{} = cmd) do
    {:ok, data_space, workspace, type, dataset_id, _} = DataStore.Data.validate_uri(old_uri)

    uri = "s3://pxc-collection-store/#{data_space}/#{workspace}/#{type}/#{dataset_id}/v#{version}"
    tag = Integrity.sign(uri)

    DataURICreated.new(cmd,
      uri: uri,
      tag: tag
    )
  end

  def execute(%Dataset{uri: uri}, %RequestTruncateDataset{} = cmd) do
    TruncateDatasetRequested.new(cmd,
      uri: uri,
      date: NaiveDateTime.utc_now()
    )
  end

  def execute(%Dataset{uri: _uri}, %TruncateDataset{} = cmd) do
    DatasetTruncated.new(cmd, date: NaiveDateTime.utc_now())
  end

  def execute(%Dataset{uri: uri}, %RequestDeleteDataset{} = cmd) do
    DeleteDatasetRequested.new(cmd,
      uri: uri,
      date: NaiveDateTime.utc_now()
    )
  end

  def execute(%Dataset{uri: _uri}, %DeleteDataset{} = cmd) do
    DatasetDeleted.new(cmd, date: NaiveDateTime.utc_now())
  end


  # State mutators

  def apply(%Dataset{} = dataset, %DataURICreated{} = event) do
    %Dataset{dataset |
      id: event.id,
      workspace: event.workspace,
      uri: event.uri,
      type: event.type,
      version: dataset.version + 1
    }
  end

  def apply(%Dataset{} = dataset, %TruncateDatasetRequested{} = event) do
    %Dataset{dataset |
      id: event.id,
      date: event.date
    }
  end

  def apply(%Dataset{} = dataset, %DatasetTruncated{} = event) do
    %Dataset{dataset |
      id: event.id,
      date: event.date
    }
  end

  def apply(%Dataset{} = dataset, %DeleteDatasetRequested{} = event) do
    %Dataset{dataset |
      id: event.id,
      date: event.date
    }
  end

  def apply(%Dataset{} = _dataset, %DatasetDeleted{} = _event), do: __MODULE__.__struct__

end
