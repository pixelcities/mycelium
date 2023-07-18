defmodule MetaStore do
  @moduledoc """
  Documentation for `MetaStore`.
  """

  @app MetaStore.Application.get_app()

  import Ecto.Query, warn: false
  import Ecto.Changeset

  require Logger

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
    UpdateSourceURI,
    DeleteSource,
    CreateMetadata,
    UpdateMetadata,
    CreateConcept,
    UpdateConcept,
    CreateCollection,
    UpdateCollection,
    UpdateCollectionSchema,
    SetCollectionColor,
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
    SetTransformerIsReady,
    SetTransformerError,
    ApproveTransformer,
    DeleteTransformer,
    CreateWidget,
    UpdateWidget,
    SetWidgetPosition,
    SetWidgetIsReady,
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

  def get_widgets_by_collection(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Widget,
      where: t.collection == ^id
    ), prefix: tenant)
  end

  def get_transformer!(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from t in Transformer,
      where: t.id == ^id
    ), prefix: tenant)
  end

  def get_transformers_by_collection(id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.all((from t in Transformer,
      where: ^id in t.collections
    ), prefix: tenant)
  end

  def get_collection!(id, opts \\ [])
  def get_collection!(nil, _opts), do: nil
  def get_collection!(id, opts) do
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

  def get_source_by_uri_and_user_id(uri, user_id, opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    Repo.one((from s in Source,
      join: c in Schema, on: s.id == c.source_id,
      join: h in assoc(c, :shares),
      where: h.principal == ^user_id and s.uri == ^uri
    ), prefix: tenant)
  end

  def get_all_uris(opts \\ []) do
    tenant = Keyword.fetch!(opts, :tenant)

    sources = Repo.all((from s in Source,
      select: [:uri]
    ), prefix: tenant)
    source_uris = Enum.map(sources, fn s -> s.uri end)

    collections = Repo.all((from c in Collection,
      select: [:uri]
    ), prefix: tenant)
    collection_uris = Enum.map(collections, fn c -> c.uri end)

    source_uris ++ collection_uris
  end


  ## Commands

  @doc """
  Create a source

  The given URI is checked for formatting and uniqueness. This protects against
  re-use of previously created URIs, which would pass the integrity check. The
  dispatch for this command is done within a mutex, to guard against racing the
  URI uniqueness check.
  """
  def create_source(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    handle = Atom.to_string(ds_id)

    lock = Mutex.await(CommandMutex, handle)

    create_source =
      attrs
      |> CreateSource.new()
      |> CreateSource.validate_uri_namespace(handle, "default")
      |> CreateSource.validate_uri_uniqueness(get_all_uris(tenant: ds_id))

    resp = handle_dispatch(create_source, metadata)

    Mutex.release(CommandMutex, lock)

    resp
  end

  @doc """
  Update a source

  The aggregate guards against changing the workspace or uri.
  """
  def update_source(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateSource.new(attrs), metadata)
  end

  @doc """
  Update the URI of a source

  This is used when a new version for a source was uploaded. The version in the URI
  is managed by the CreateDataURI command.
  """
  def update_source_uri(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateSourceURI.new(attrs), metadata)
  end

  def delete_source(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(DeleteSource.new(attrs), metadata)
  end

  @doc """
  Publish some metadata

  Metadata is for clients only. It consists of a key with an encrypted value that is shared across
  the workspace.
  """
  def create_metadata(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(CreateMetadata.new(attrs), metadata)
  end

  @doc """
  Update the metadata
  """
  def update_metadata(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateMetadata.new(attrs), metadata)
  end

  def create_concept(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(CreateConcept.new(attrs), metadata)
  end

  def update_concept(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateConcept.new(attrs), metadata)
  end

  @doc """
  Create a collection

  Users are only ever able to create source collections, which requires
  that the URI matches the source and that they have access to the original
  source.
  """
  def create_collection(%{"uri" => [uri, _tag]} = attrs, %{"user_id" => user_id, "ds_id" => ds_id} = metadata) do
    create_collection =
      attrs
      |> CreateCollection.new()
      |> CreateCollection.validate_source(get_source_by_uri_and_user_id(uri, user_id, tenant: ds_id))

    handle_dispatch(create_collection, metadata)
  end

  def update_collection(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateCollection.new(attrs), metadata)
  end

  def update_collection_schema(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateCollectionSchema.new(attrs), metadata)
  end

  def set_collection_color(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetCollectionColor.new(attrs), metadata)
  end

  def set_collection_position(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetCollectionPosition.new(attrs), metadata)
  end

  def set_collection_is_ready(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetCollectionIsReady.new(attrs), metadata)
  end

  def add_collection_target(%{"id" => _id, "workspace" => _workspace, "target" => target} = attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    transformer = MetaStore.get_transformer!(target, tenant: ds_id)

    if transformer do
      command =
        attrs
        |> AddCollectionTarget.new()
        |> AddCollectionTarget.validate_transformer_target(transformer)

      handle_dispatch(command, metadata)

    else
      widget = MetaStore.get_widget!(target, tenant: ds_id)

      if widget do
        command =
          attrs
          |> AddCollectionTarget.new()
          |> AddCollectionTarget.validate_widget_target(widget)

        handle_dispatch(command, metadata)
      else
        dispatch_error(:target_does_not_exist, metadata)
      end
    end
  end

  def remove_collection_target(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(RemoveCollectionTarget.new(attrs), metadata)
  end

  @doc """
  Delete collection

  Can only delete source collections, as transformer collections are managed
  by the transformer itself. See: delete_transformer/2
  """
  def delete_collection(%{"id" => id, "workspace" => _workspace} = attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    collection = MetaStore.get_collection!(id, tenant: ds_id)

    if collection && collection.type == "source" do
      if length(collection.targets) == 0 do
        handle_dispatch(DeleteCollection.new(attrs), metadata)

      # Verify the targets are still live
      else
        unless Enum.any?(Enum.map(collection.targets, fn t ->
          MetaStore.get_transformer!(t, tenant: ds_id) != nil
        end)) do
          handle_dispatch(DeleteCollection.new(attrs), metadata)
        else
          dispatch_error(:cannot_delete_source_with_active_targets, metadata)
        end
      end

    else
      if is_nil(collection) do # Better be safe than sorry
        handle_dispatch(DeleteCollection.new(attrs), metadata)
      else
        dispatch_error(:cannot_delete_collection, metadata)
      end
    end
  end

  @doc """
  Create a transformer

  Transformers are usually created without any inputs, but will receive one or more
  inputs later on. The transformer will execute a transformation on the incoming data
  (usually a collection) and eventually put the results in a new collection.
  """
  def create_transformer(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(CreateTransformer.new(attrs), metadata)
  end

  def update_transformer(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateTransformer.new(attrs), metadata)
  end

  def set_transformer_position(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetTransformerPosition.new(attrs), metadata)
  end

  def add_transformer_target(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(AddTransformerTarget.new(attrs), metadata)
  end

  def remove_transformer_target(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(RemoveTransformerTarget.new(attrs), metadata)
  end

  def add_transformer_input(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    command = AddTransformerInput.new(attrs)

    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  @doc """
  Update the transformer WAL

  The WAL is verified to have the expected structure, and the aggregate guards
  against the use of columns the user does not have access to.
  """
  def update_transformer_wal(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateTransformerWAL.new(attrs), metadata)
  end

  def set_transformer_is_ready(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetTransformerIsReady.new(attrs), metadata)
  end

  def set_transformer_error(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetTransformerError.new(attrs), metadata)
  end

  @doc """
  Approve a transformer

  For certain transformers, they need to be approved by all relevant parties before its
  safe to start the task execution. By sharing their signature each party will signal that
  they have approved this transformer. Later, during task execution, they will verify
  their own signature, that is now sent along the transformer, before doing anything.
  """
  def approve_transformer(attrs, %{"user_id" => _user_id, "ds_id" => _ds_id} = metadata) do
    handle_dispatch(ApproveTransformer.new(attrs), metadata)
  end

  @doc """
  Delete a transformer, including it's connectors

  This will delete all the incoming and outgoing connectors, and also
  the resulting collection. Finally the transformer itself is deleted.
  """
  def delete_transformer(%{"id" => id, "workspace" => workspace} = attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    transformer = MetaStore.get_transformer!(id, tenant: ds_id)

    if transformer do
      incoming_collection_cmds = Enum.map(transformer.collections, fn c -> RemoveCollectionTarget.new(%{:id => c, :workspace => workspace, :target => id}) end)
      incoming_transformer_cmds = Enum.map(transformer.transformers, fn t -> RemoveTransformerTarget.new(%{:id => t, :workspace => workspace, :target => id}) end)
      outgoing_collection_cmds = Enum.map(transformer.targets, fn t -> DeleteCollection.new(%{:id => t, :workspace => workspace}) end)
      delete_self_cmd = DeleteTransformer.new(attrs)

      commands = incoming_collection_cmds ++ incoming_transformer_cmds ++ outgoing_collection_cmds ++ [ delete_self_cmd ]

      # TODO: Handle rollbacks when an error happens in one of the alter commands
      Enum.reduce_while(commands, {:ok, :done}, fn command, _acc ->
        reply = @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata)

        # Also continue on :no_such_target, to recover from bad state
        if reply == :ok or reply == {:error, :no_such_target} do
          {:cont, {:ok, :done}}
        else
          {:halt, reply}
        end
      end)
    else
      {:error, :already_deleted}
    end
  end

  @doc """
  Create a widget

  Widgets require a collection input to be usuable. They implement "export"
  behaviour within the workflows. For example, data from a collection can
  be visualized using various charts.

  This is achieved by storing the visualization result in the widget itself,
  so that the collection data does not have to be exposed to, for example, a
  public report.
  """
  def create_widget(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(CreateWidget.new(attrs), metadata)
  end

  def update_widget(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(UpdateWidget.new(attrs), metadata)
  end

  def set_widget_position(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetWidgetPosition.new(attrs), metadata)
  end

  def set_widget_is_ready(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(SetWidgetIsReady.new(attrs), metadata)
  end

  def add_widget_input(attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    command = AddWidgetInput.new(attrs)

    causation_id = Map.get(metadata, :causation_id, UUID.uuid4())
    correlation_id = Map.get(metadata, :correlation_id, UUID.uuid4())

    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), causation_id: causation_id, correlation_id: correlation_id, metadata: metadata) do
      {:ok, :done}
    else
      reply -> reply
    end
  end

  def put_widget_setting(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(PutWidgetSetting.new(attrs), metadata)
  end

  def publish_widget(attrs, %{"user_id" => _user_id} = metadata) do
    handle_dispatch(PublishWidget.new(attrs), metadata)
  end

  def delete_widget(%{"id" => id, "workspace" => workspace} = attrs, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    widget = MetaStore.get_widget!(id, tenant: ds_id)

    incoming_collection_cmd = if widget.collection, do: [RemoveCollectionTarget.new(%{:id => widget.collection, :workspace => workspace, :target => id})], else: []
    delete_self_cmd = DeleteWidget.new(attrs)

    Enum.reduce_while(incoming_collection_cmd ++ [delete_self_cmd], {:ok, :done}, fn command, _acc ->
      reply = @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata)

      if reply == :ok or reply == {:error, :no_such_target} do
        {:cont, {:ok, :done}}
      else
        {:halt, reply}
      end
    end)
  end


  defp handle_dispatch(command, %{"user_id" => _user_id, "ds_id" => ds_id} = metadata) do
    with :ok <- @app.validate_and_dispatch(command, consistency: :strong, application: Module.concat(@app, ds_id), metadata: metadata) do
      {:ok, :done}
    else
      reply ->
        case reply do
          {:error, :unregistered_command} -> reply
          {:error, :consistency_timeout} -> reply
          {:error, error} ->
            Logger.error("Error dispatching command #{inspect(command)} with metadata #{inspect(metadata)}: #{inspect(error)}")

            dispatch_error(error, metadata)
          err -> err
        end
    end
  end

  # Dispatch the error as a notification. This will upgrade the error
  # to :ok if the notification was dispatched correctly.
  defp dispatch_error(error, %{"user_id" => user_id} = metadata) do
    Landlord.notify_user(%{
      id: Ecto.UUID.generate(),
      type: "error",
      message: format_error(error),
      receiver: user_id,
      is_urgent: true
    }, metadata)
  end

  defp format_error({:validation_failure, %Ecto.Changeset{} = reason}) do
    errors = traverse_errors(reason, fn {msg, _opts} -> msg end)

    "Validation failure: " <> Enum.join(Enum.map(Map.to_list(errors), fn {k, v} -> Atom.to_string(k) <> " " <> Enum.join(v, " and ") end), ", ")
  end

  defp format_error(reason) when is_atom(reason) do
    [head | tail] = String.split(Atom.to_string(reason), "_")

    Enum.join([String.capitalize(head)] ++ tail, " ")
  end

  defp format_error(_reason), do: "Internal server error"

end
