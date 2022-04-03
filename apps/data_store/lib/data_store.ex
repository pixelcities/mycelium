defmodule DataStore do
  @moduledoc """
  Documentation for `DataStore`.
  """

  @app DataStore.Application.get_app()

  alias Core.Commands.CreateDataURI


  @doc """
  Generate a unique dataset URI, including temporary session information
  """
  def request_data_uri(attrs, %{user_id: _user_id} = metadata) do
    command =
      attrs
      |> CreateDataURI.new()

    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat([@app, :ds1]), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def generate_data_tokens(uri, user), do: DataStore.DataTokens.generate_data_tokens(uri, user.id)
end
