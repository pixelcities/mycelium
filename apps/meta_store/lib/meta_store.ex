defmodule MetaStore do
  @moduledoc """
  Documentation for `MetaStore`.
  """

  @app MetaStore.Application.get_app()

  import Ecto.Query, warn: false

  alias MetaStore.Repo
  alias MetaStore.Projections.{
    Transformer,
    Collection,
    Source,
    Schema,
    Column,
    Share
  }
  alias Core.Commands.{
    CreateSource,
    UpdateSource,
    CreateMetadata,
    UpdateMetadata,
    CreateCollection,
    UpdateCollection,
    UpdateCollectionSchema,
    SetCollectionPosition,
    SetCollectionIsReady,
    AddCollectionTarget,
    CreateTransformer,
    UpdateTransformer,
    SetTransformerPosition,
    AddTransformerTarget,
    AddTransformerInput,
    UpdateTransformerWAL
  }


  ## Database getters

  def get_transformer!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from t in Transformer,
      where: t.id == ^id
    ), prefix: tenant)
  end

  def get_collection!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from c in Collection,
      where: c.id == ^id,
      preload: [:schema]
    ), prefix: tenant)
  end

  def get_schema!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from c in Schema,
      where: c.id == ^id,
      preload: [:columns, :shares]
    ), prefix: tenant)
  end

  def get_column!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from c in Column,
      where: c.id == ^id,
      preload: [:shares]
    ), prefix: tenant)
  end

  def get_share!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from c in Share,
      where: c.id == ^id
    ), prefix: tenant)
  end

  def get_collections(opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from c in Collection), prefix: tenant)
  end

  def get_collections_by_user(user, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from c in Collection,
      join: s in Schema, on: c.id == s.collection_id,
      join: h in assoc(s, :shares),
      where: h.principal == ^user.email
    ), prefix: tenant)
  end

  def get_sources(opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from s in Source), prefix: tenant)
  end

  def get_sources_by_user(user, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from s in Source,
      join: c in Schema, on: s.id == c.source_id,
      join: h in assoc(c, :shares),
      where: h.principal == ^user.email
    ), prefix: tenant)
  end


  ## Commands

  @doc """
  Create a source

  A source is just a shell that inits a source by creating a
  data URI, exchanging shares, etc.
  """
  def create_source(attrs, %{user_id: _user_id} = metadata) do
    handle = Atom.to_string(Map.get(metadata, :ds_id, :ds1))

    create_source =
      attrs
      |> CreateSource.new()
      |> CreateSource.validate_uri_namespace(handle, "default")

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

  def update_collection_schema(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateCollectionSchema.new(attrs), metadata)
  end

  def set_collection_position(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(SetCollectionPosition.new(attrs), metadata)
  end

  def set_collection_is_ready(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(SetCollectionIsReady.new(attrs), metadata)
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

    ds_id = Map.get(metadata, :ds_id, :ds1)
    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def update_transformer_wal(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateTransformerWAL.new(attrs), metadata)
  end


  defp handle_dispatch(command, metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

end
