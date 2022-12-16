defmodule DataStore.Managers.DatasetProcessManager do
  use Commanded.ProcessManagers.ProcessManager,
    name: __MODULE__

  @derive Jason.Encoder
  defstruct [
    :id,
    :workspace,
    :uri
  ]

  alias DataStore.Managers.DatasetProcessManager
  alias DataStore.Data
  alias Core.Commands.{
    RequestDeleteDataset,
    TruncateDataset,
    DeleteDataset
  }
  alias Core.Events.{
    DataURICreated,
    TruncateDatasetRequested,
    DeleteDatasetRequested,
    SourceDeleted,
    TransformerDeleted
  }

  # Process routing

  def interested?(%DataURICreated{id: id}), do: {:start, id}
  def interested?(%SourceDeleted{id: id}), do: {:continue!, id}
  def interested?(%TransformerDeleted{id: id}), do: {:continue!, id}
  def interested?(%TruncateDatasetRequested{id: id}), do: {:continue, id}
  def interested?(%DeleteDatasetRequested{id: id}), do: {:continue, id}
  def interested?(_event), do: false


  # Command dispatch

  def handle(%DatasetProcessManager{uri: _uri} = _pm, %SourceDeleted{} = event) do
    %RequestDeleteDataset{
      id: event.id
    }
  end

  def handle(%DatasetProcessManager{uri: _uri} = _pm, %TransformerDeleted{} = event) do
    %RequestDeleteDataset{
      id: event.id
    }
  end

  def handle(%DatasetProcessManager{uri: uri} = _pm, %TruncateDatasetRequested{} = event) do
    with :ok <- Data.truncate_dataset(uri) do
      %TruncateDataset{
        id: event.id,
      }

    else
      err -> err
    end
  end

  def handle(%DatasetProcessManager{uri: uri} = _pm, %DeleteDatasetRequested{} = event) do
    with :ok <- Data.delete_dataset(uri) do
      %DeleteDataset{
        id: event.id,
      }

    else
      err -> err
    end
  end


  # Error handlers

  # When a source or transformer is deleted we are interested in the event, but only if the id
  # matches a dataset (our PM). There are various situations where the dataset was not yet created,
  # so we simply do not care about handling it here.
  def error({:error, {:continue!, :process_not_started}}, _failure_message, _failure_context) do
    :skip
  end

  # State mutators

  def apply(%DatasetProcessManager{} = pm, %DataURICreated{} = event) do
    %DatasetProcessManager{pm |
      id: event.id,
      workspace: event.workspace,
      uri: event.uri
    }
  end

end
