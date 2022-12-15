defmodule LiaisonServerWeb.DataSpaceChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Tracker
  alias Landlord.Tenants


  @impl true
  def join("ds:" <> handle, payload, socket) do
    user = socket.assigns.current_user
    maybe_ds_id = Tenants.to_atom(user, handle)

    if authorized?(user, maybe_ds_id, payload) do
      {:ok, ds_id} = maybe_ds_id
      socket = assign(socket, :current_ds, ds_id)

      send(self(), :after_join)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Phoenix.Tracker.track(Tracker, self(), "ds:" <> Atom.to_string(socket.assigns.current_ds), socket.assigns.current_user.id, %{
      ds_id: socket.assigns.current_ds,
      online_at: inspect(System.system_time(:second))
    })

    {:noreply, socket}
  end


  # Re(p)lay handlers
  #
  # These handlers subscribe the client to the appropiate streams, so that events are broadcasted when they occur.
  #
  # For most relays, the events are replayed from the beginning of time so that client side state can be restored. The
  # subscribed streams are often shared accross the workspace, with the exception of the secret shares.

  @impl true
  def handle_in("init", %{"type" => "events", "payload" => event_number}, socket), do: handle_subscribe(LiaisonServer.Workflows.RelayEvents, socket, true, event_number)

  @impl true
  def handle_in("init", %{"type" => "secrets"}, socket), do: handle_subscribe(LiaisonServer.Workflows.RelaySecrets, socket)

  @impl true
  def handle_in("init", %{"type" => "tasks"}, socket), do: handle_subscribe(LiaisonServer.Workflows.RelayTasks, socket)


  # Command handlers

  @impl true
  def handle_in("action", %{"type" => "ShareSecret"} = action, socket), do: handle_action(&KeyX.share_secret/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateDataURI"} = action, socket), do: handle_action(&DataStore.request_data_uri/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateSource"} = action, socket), do: handle_action(&MetaStore.create_source/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateSource"} = action, socket), do: handle_action(&MetaStore.update_source/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "DeleteSource"} = action, socket), do: handle_action(&MetaStore.delete_source/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateMetadata"} = action, socket), do: handle_action(&MetaStore.create_metadata/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateMetadata"} = action, socket), do: handle_action(&MetaStore.update_metadata/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateConcept"} = action, socket), do: handle_action(&MetaStore.create_concept/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateConcept"} = action, socket), do: handle_action(&MetaStore.update_concept/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateCollection"} = action, socket), do: handle_action(&MetaStore.create_collection/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateCollection"} = action, socket), do: handle_action(&MetaStore.update_collection/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateCollectionSchema"} = action, socket), do: handle_action(&MetaStore.update_collection_schema/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "SetCollectionPosition"} = action, socket), do: handle_action(&MetaStore.set_collection_position/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "SetCollectionIsReady"} = action, socket), do: handle_action(&MetaStore.set_collection_is_ready/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "AddCollectionTarget"} = action, socket), do: handle_action(&MetaStore.add_collection_target/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "DeleteCollection"} = action, socket), do: handle_action(&MetaStore.delete_collection/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateTransformer"} = action, socket), do: handle_action(&MetaStore.create_transformer/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateTransformer"} = action, socket), do: handle_action(&MetaStore.update_transformer/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "SetTransformerPosition"} = action, socket), do: handle_action(&MetaStore.set_transformer_position/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "AddTransformerTarget"} = action, socket), do: handle_action(&MetaStore.add_transformer_target/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "AddTransformerInput"} = action, socket), do: handle_action(&MetaStore.add_transformer_input/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateTransformerWAL"} = action, socket), do: handle_action(&MetaStore.update_transformer_wal/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "DeleteTransformer"} = action, socket), do: handle_action(&MetaStore.delete_transformer/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateWidget"} = action, socket), do: handle_action(&MetaStore.create_widget/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateWidget"} = action, socket), do: handle_action(&MetaStore.update_widget/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "SetWidgetPosition"} = action, socket), do: handle_action(&MetaStore.set_widget_position/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "AddWidgetInput"} = action, socket), do: handle_action(&MetaStore.add_widget_input/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "PutWidgetSetting"} = action, socket), do: handle_action(&MetaStore.put_widget_setting/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "PublishWidget"} = action, socket), do: handle_action(&MetaStore.publish_widget/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "DeleteWidget"} = action, socket), do: handle_action(&MetaStore.delete_widget/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CompleteTask"} = action, socket), do: handle_action(&Maestro.complete_task/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreatePage"} = action, socket), do: handle_action(&ContentServer.create_page/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdatePage"} = action, socket), do: handle_action(&ContentServer.update_page/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "SetPageOrder"} = action, socket), do: handle_action(&ContentServer.set_page_order/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "DeletePage"} = action, socket), do: handle_action(&ContentServer.delete_page/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "CreateContent"} = action, socket), do: handle_action(&ContentServer.create_content/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateContent"} = action, socket), do: handle_action(&ContentServer.update_content/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateContentDraft"} = action, socket), do: handle_action(&ContentServer.update_content_draft/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "DeleteContent"} = action, socket), do: handle_action(&ContentServer.delete_content/2, action, socket)


  defp handle_action(func, action, socket) do
    user = socket.assigns.current_user
    ds_id = socket.assigns.current_ds

    with {:ok, :done} <- func.(Map.fetch!(action, "payload"), %{user_id: user.id, ds_id: ds_id}) do
      {:noreply, socket}
    else
      err -> {:stop, err, socket}
    end
  end

  # TODO: stop on leave channel
  defp handle_subscribe(module, socket, restart \\ false, restart_from \\ 0) do
    user = socket.assigns.current_user
    ds_id = socket.assigns.current_ds

    app = Module.concat(LiaisonServer.App, socket.assigns.current_ds)

    # Start an event handler that will broadcast all relevant events
    {:ok, _pid} = DynamicSupervisor.start_child(LiaisonServer.RelayEventSupervisor, {module,
      application: app,
      ds_id: ds_id,
      user_id: user.id,
      workspace: "default"
    })

    if restart do
      case LiaisonServer.EventHistory.replay_from(restart_from, ds_id, user.id) do
        :ok -> {:reply, :ok, socket}
        :error -> {:reply, :error, socket}
      end
    else
      {:reply, :ok, socket}
    end
  end


  # Add authorization logic here as required.
  defp authorized?(user, _ds_id, _payload) when user.confirmed_at == nil, do: false
  defp authorized?(_user, {:ok, ds_id}, _payload) when is_atom(ds_id), do: true
  defp authorized?(_user, _ds_id, _payload), do: false

end
