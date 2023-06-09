defmodule LiaisonServer.Workflows.RelaySecrets do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :origin

  require Logger

  alias LiaisonServer.EventStore
  alias Core.Events.SecretShared

  @impl true
  def init(config) do
    {_workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {ds_id, config} = Keyword.pop(config, :ds_id)

    name = Module.concat([__MODULE__, ds_id, user_id])
    channel = "ds:" <> (ds_id |> to_string())

    config = Keyword.put_new(config, :state, %{channel: channel, user_id: user_id})
    config = Keyword.put_new(config, :name, name)
    config = Keyword.put_new(config, :subscribe_to, "secrets-" <> user_id)

    :timer.apply_after(300_000, __MODULE__, :task, [channel, user_id, ds_id])

    {:ok, config}
  end

  @impl true
  def handle(%SecretShared{} = event, metadata) do
    %{state: state} = metadata

    broadcast(state.channel, state.user_id, event)
  end

  def task(channel, user_id, ds_id) do
    message_ids = KeyX.Protocol.get_old_messages_by_user_id(user_id)

    if length(message_ids) > 0 do
      Logger.warning("Encountered lost messages for user \"#{user_id}\". Replaying..")
      replay_lost_messages(channel, user_id, ds_id, message_ids)
    end
  end

  defp replay_lost_messages(channel, user_id, ds_id, message_ids) do
    EventStore.stream_backward("secrets-" <> user_id, -1, name: Module.concat(EventStore, ds_id))
    |> Enum.reduce_while(message_ids, fn event, acc ->
      message_id = event.data.message_id

      if message_id in message_ids do
        broadcast(channel, user_id, event.data)

        if length(acc) == 1 do
          {:halt, []}
        else
          {:cont, acc -- [message_id]}
        end
      else
        {:cont, acc}
      end
    end)
  end

  defp broadcast(channel, user_id, event) do
    if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, channel), %{}), user_id) do
      LiaisonServerWeb.Endpoint.broadcast("user:" <> user_id, "event", %{"type" => "SecretShared", "payload" => event})

      :ok
    else
      {:error, :disconnect}
    end
  end
end
