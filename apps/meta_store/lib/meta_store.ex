defmodule MetaStore do
  @moduledoc """
  Documentation for `MetaStore`.
  """

  @app MetaStore.Application.get_app()

  alias Core.Commands.{
    CreateSource,
    UpdateSource,
    CreateMetadata,
    UpdateMetadata,
    CreateCollection,
    UpdateCollection,
    SetCollectionPosition,
    AddCollectionTarget,
    CreateTransformer,
    UpdateTransformer,
    SetTransformerPosition,
    AddTransformerTarget,
    AddTransformerInput,
    UpdateTransformerWAL
  }


  @doc """
  Create a source

  A source is just a shell that inits a source by creating a
  data URI, exchanging shares, etc.
  """
  def create_source(attrs, %{user_id: _user_id} = metadata) do
    create_source =
      attrs
      |> CreateSource.new()
      |> CreateSource.validate_uri_namespace("ds1", "default")

    handle_dispatch(create_source, metadata)
  end

  @doc """
  Update a source

  Only the source id is required, any additional fields are upserted
  """
  def update_source(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateSource.new(attrs), metadata)
  end

  @doc """
  Publish some metadata

  Metadata is for clients only. It consists of a key with an encrypted value that is shared across
  the workspace.
  """
  def create_metadata(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreateMetadata.new(attrs), metadata)
  end

  @doc """
  Update the metadata
  """
  def update_metadata(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateMetadata.new(attrs), metadata)
  end

  def create_collection(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreateCollection.new(attrs), metadata)
  end

  def update_collection(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateCollection.new(attrs), metadata)
  end

  def set_collection_position(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(SetCollectionPosition.new(attrs), metadata)
  end

  def add_collection_target(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(AddCollectionTarget.new(attrs), metadata)
  end

  def create_transformer(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreateTransformer.new(attrs), metadata)
  end

  def update_transformer(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateTransformer.new(attrs), metadata)
  end

  def set_transformer_position(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(SetTransformerPosition.new(attrs), metadata)
  end

  def add_transformer_target(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(AddTransformerTarget.new(attrs), metadata)
  end

  def add_transformer_input(attrs, metadata) do
    command = AddTransformerInput.new(attrs)

    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat([@app, :ds1]), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def update_transformer_wal(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateTransformerWAL.new(attrs), metadata)
  end


  defp handle_dispatch(command, metadata) do
    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat([@app, :ds1]), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
