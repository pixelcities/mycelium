defmodule MetaStore do
  @moduledoc """
  Documentation for `MetaStore`.
  """

  @app MetaStore.Application.get_app()

  import Ecto.Query, warn: false

  alias MetaStore.Repo
  alias MetaStore.Projections.{
    Widget,
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
    DeleteSource,
    CreateMetadata,
    UpdateMetadata,
    CreateConcept,
    UpdateConcept,
    CreateCollection,
    UpdateCollection,
    UpdateCollectionSchema,
    SetCollectionPosition,
    SetCollectionIsReady,
    AddCollectionTarget,
    RemoveCollectionTarget,
    DeleteCollection,
    CreateTransformer,
    UpdateTransformer,
    SetTransformerPosition,
    AddTransformerTarget,
    RemoveTransformerTarget,
    AddTransformerInput,
    UpdateTransformerWAL,
    DeleteTransformer,
    CreateWidget,
    UpdateWidget,
    SetWidgetPosition,
    AddWidgetInput,
    PutWidgetSetting,
    PublishWidget,
    DeleteWidget
  }


  ## Database getters

  def get_widget!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from t in Widget,
      where: t.id == ^id
    ), prefix: tenant)
  end

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
      preload: [columns: [shares: []], shares: []]
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
      where: h.principal == ^user.id
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
      where: h.principal == ^user.id
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

  def delete_source(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(DeleteSource.new(attrs), metadata)
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

  def create_concept(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreateConcept.new(attrs), metadata)
  end

  def update_concept(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateConcept.new(attrs), metadata)
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

  def add_collection_target(%{"id" => id, "workspace" => _workspace, "target" => target} = attrs, %{user_id: _user_id} = metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)

    transformer = MetaStore.get_transformer!(target, tenant: ds_id)

    if transformer do
      max_inputs = if transformer.type == "merge", do: 2, else: 1

      if length(transformer.collections) < max_inputs do
        handle_dispatch(AddCollectionTarget.new(attrs), metadata)
      else
        {:error, :too_many_inputs}
      end

    else
      widget = MetaStore.get_widget!(target, tenant: ds_id)

      if widget do
        unless widget.collection do
          handle_dispatch(AddCollectionTarget.new(attrs), metadata)
        else
          {:error, :target_already_has_input}
        end
      else
        {:error, :target_does_not_exist}
      end
    end
  end

  def remove_collection_target(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(RemoveCollectionTarget.new(attrs), metadata)
  end

  @doc """
  Delete collection

  Can only delete source collections, as transformer collections are managed
  by the transformer itself. See: delete_transformer/2
  """
  def delete_collection(%{"id" => id, "workspace" => _workspace} = attrs, %{user_id: _user_id} = metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)
    collection = MetaStore.get_collection!(id, tenant: ds_id)

    if collection.type == "source" and length(collection.targets) == 0 do
      handle_dispatch(DeleteCollection.new(attrs), metadata)
    else
      {:error, :cannot_delete_collection}
    end
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

  def remove_transformer_target(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(RemoveTransformerTarget.new(attrs), metadata)
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

  @doc """
  Delete a transformer, including it's connectors

  This will delete all the incoming and outgoing connectors, and also
  the resulting collection. Finally the transformer itself is deleted.
  """
  def delete_transformer(%{"id" => id, "workspace" => workspace} = attrs, %{user_id: _user_id} = metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)

    transformer = MetaStore.get_transformer!(id, tenant: ds_id)

    incoming_collection_cmds = Enum.map(transformer.collections, fn c -> RemoveCollectionTarget.new(%{:id => c, :workspace => workspace, :target => id}) end)
    incoming_transformer_cmds = Enum.map(transformer.transformers, fn t -> RemoveTransformerTarget.new(%{:id => t, :workspace => workspace, :target => id}) end)
    outgoing_collection_cmds = Enum.map(transformer.targets, fn t -> DeleteCollection.new(%{:id => t, :workspace => workspace}) end)
    delete_self_cmd = DeleteTransformer.new(attrs)

    commands = incoming_collection_cmds ++ incoming_transformer_cmds ++ outgoing_collection_cmds ++ [ delete_self_cmd ]

    Enum.reduce_while(commands, {:ok, :done}, fn command, _acc ->
      reply = @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata)

      if reply == :ok do
        {:cont, {:ok, :done}}
      else
        {:halt, reply}
      end
    end)
  end

  def create_widget(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(CreateWidget.new(attrs), metadata)
  end

  def update_widget(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(UpdateWidget.new(attrs), metadata)
  end

  def set_widget_position(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(SetWidgetPosition.new(attrs), metadata)
  end

  def add_widget_input(attrs, metadata) do
    command = AddWidgetInput.new(attrs)

    ds_id = Map.get(metadata, :ds_id, :ds1)
    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def put_widget_setting(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(PutWidgetSetting.new(attrs), metadata)
  end

  def publish_widget(attrs, %{user_id: _user_id} = metadata) do
    handle_dispatch(PublishWidget.new(attrs), metadata)
  end

  def delete_widget(%{"id" => id, "workspace" => workspace} = attrs, %{user_id: _user_id} = metadata) do
    ds_id = Map.get(metadata, :ds_id, :ds1)

    widget = MetaStore.get_widget!(id, tenant: ds_id)

    incoming_collection_cmd = RemoveCollectionTarget.new(%{:id => widget.collection, :workspace => workspace, :target => id})
    delete_self_cmd = DeleteWidget.new(attrs)

    Enum.reduce_while([incoming_collection_cmd, delete_self_cmd], {:ok, :done}, fn command, _acc ->
      reply = @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata)

      if reply == :ok do
        {:cont, {:ok, :done}}
      else
        {:halt, reply}
      end
    end)
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
