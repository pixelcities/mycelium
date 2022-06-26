defmodule LiaisonServerWeb.UserChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Tracker
  alias LiaisonServerWeb.Registry.UserDataSpaces

  @impl true
  def join("user:" <> user_id, payload, socket) do
    user = socket.assigns.current_user

    if user_id == user.id and authorized?(user, payload) do
      send(self(), :after_join)

      Registry.register(UserDataSpaces, user.id, nil)

      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    user_id = socket.assigns.current_user.id
    {:ok, _} = Phoenix.Tracker.track(Tracker, self(), "user:" <> user_id, user_id, %{
      ds_id: Map.get(socket.assigns, :current_ds),
      online_at: inspect(System.system_time(:second))
    })

    {:noreply, socket}
  end

  def handle_info({:set_data_space, ds_id}, socket) do
    socket = assign(socket, :current_ds, ds_id)

    {:noreply, socket}
  end

  # Re(p)lay handlers
  #
  # These handlers subscribe the client to the appropiate streams, so that events are broadcasted when they occur.
  #
  # For most relays, the events are replayed from the beginning of time so that client side state can be restored. The
  # subscribed streams are often shared accross the workspace, with the exception of the secret shares.

  @impl true
  def handle_in("init", %{"type" => "events"}, socket), do: handle_subscribe(LiaisonServer.Workflows.RelayEvents, socket)

  @impl true
  def handle_in("init", %{"type" => "secrets"}, socket), do: handle_subscribe(LiaisonServer.Workflows.RelaySecrets, socket, false)

  @impl true
  def handle_in("init", %{"type" => "tasks"}, socket), do: handle_subscribe(LiaisonServer.Workflows.RelayTasks, socket, false)


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
  def handle_in("action", %{"type" => "CreateMetadata"} = action, socket), do: handle_action(&MetaStore.create_metadata/2, action, socket)

  @impl true
  def handle_in("action", %{"type" => "UpdateMetadata"} = action, socket), do: handle_action(&MetaStore.update_metadata/2, action, socket)

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
  def handle_in("action", %{"type" => "CompleteTask"} = action, socket), do: handle_action(&Maestro.complete_task/2, action, socket)


  # Add authorization logic here as required.
  defp authorized?(user, _payload) when user.confirmed_at == nil, do: false
  defp authorized?(_user, _payload), do: true


  defp handle_action(func, action, socket) do
    user = socket.assigns.current_user
    ds_id = socket.assigns.current_ds

    with {:ok, :done} <- func.(Map.fetch!(action, "payload"), %{user_id: user.id, ds_id: ds_id}) do
      {:noreply, socket}
    else
      err -> {:stop, err, socket}
    end
  end

  defp handle_subscribe(module, socket, restart \\ true) do
    user = socket.assigns.current_user

    app = Module.concat(LiaisonServer.App, socket.assigns.current_ds)

    # (Re)start an event handler that will broadcast all relevant events in history
    {:ok, pid} = DynamicSupervisor.start_child(LiaisonServer.RelayEventSupervisor, {module, application: app, user_id: user.id, workspace: "default"})

    if restart do
      send(pid, :reset)
    end

    {:noreply, socket}
  end

end
