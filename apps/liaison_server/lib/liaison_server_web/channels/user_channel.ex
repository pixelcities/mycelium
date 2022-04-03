defmodule LiaisonServerWeb.UserChannel do
  use LiaisonServerWeb, :channel

  require Logger

  alias LiaisonServerWeb.Presence

  @impl true
  def join("user:" <> user_id, payload, socket) do
    user = socket.assigns.current_user

    send(self(), :after_join)

    if user_id == user.id and authorized?(payload) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{
      online_at: inspect(System.system_time(:second))
    })

    push(socket, "presence_state", Presence.list(socket))
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
  def handle_in("action", %{"type" => "SetCollectionPosition"} = action, socket), do: handle_action(&MetaStore.set_collection_position/2, action, socket)

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


  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp handle_action(func, action, socket) do
    user = socket.assigns.current_user

    with {:ok, :done} <- func.(Map.fetch!(action, "payload"), %{user_id: user.id}) do
      {:noreply, socket}
    else
      err -> {:stop, err, socket}
    end
  end

  defp handle_subscribe(module, socket, restart \\ true) do
    user = socket.assigns.current_user

    # (Re)start an event handler that will broadcast all relevant events in history
    {:ok, pid} = DynamicSupervisor.start_child(LiaisonServer.RelayEventSupervisor, {module, application: Module.concat([LiaisonServer.App, :ds1]), user_id: user.id, workspace: "default"})

    if restart do
      send(pid, :reset)
    end

    {:noreply, socket}
  end

end
