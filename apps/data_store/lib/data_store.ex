defmodule DataStore do
  @moduledoc """
  Documentation for `DataStore`.
  """

  @app DataStore.Application.get_app()

  alias Core.Commands.{
    CreateDataURI,
    RequestDeleteDataset,
    RequestTruncateDataset
  }

  @doc """
  Generate a unique dataset URI
  """
  def request_data_uri(attrs, %{"user_id" => _user_id, "ds_id" => _ds_id} = metadata) do
    handle_dispatch(CreateDataURI.new(attrs), metadata)
  end

  def delete_dataset(%{"id" => _id} = attrs, %{"user_id" => _user_id, "ds_id" => _ds_id} = metadata) do
    handle_dispatch(RequestDeleteDataset.new(attrs), metadata)
  end

  def truncate_dataset(%{"id" => _id} = attrs, %{"user_id" => _user_id, "ds_id" => _ds_id} = metadata) do
    handle_dispatch(RequestTruncateDataset.new(attrs), metadata)
  end

  def generate_data_tokens(uri, mode, user, ip), do: DataStore.DataTokens.generate_data_tokens(uri, mode, user, ip)


  defp handle_dispatch(command, %{"ds_id" => ds_id} = metadata) do
    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end
end
