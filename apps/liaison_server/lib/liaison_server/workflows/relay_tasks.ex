defmodule LiaisonServer.Workflows.RelayTasks do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :current

  alias Core.Events.{
    TaskAssigned,
    TaskCompleted,
    TaskFailed
  }

  @impl true
  def init(config) do
    {_workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {ds_id, config} = Keyword.pop(config, :ds_id)
    name = Module.concat([__MODULE__, ds_id, user_id])

    config = Keyword.put_new(config, :state, %{channel: "ds:" <> (ds_id |> to_string()), user_id: user_id})
    config = Keyword.put_new(config, :name, name)

    {:ok, config}
  end

  @impl true
  def handle(%TaskAssigned{} = event, metadata) do
    %{state: state} = metadata

    broadcast("TaskAssigned", state, event, event.worker)
  end

  @impl true
  def handle(%TaskCompleted{} = event, metadata) do
    %{state: state} = metadata

    broadcast("TaskCompleted", state, event, Map.get(metadata, "user_id"))
  end

  @impl true
  def handle(%TaskFailed{} = event, metadata) do
    %{state: state} = metadata

    broadcast("TaskFailed", state, event, Map.get(metadata, "user_id"))
  end

  defp broadcast(type, state, event, user_id) do
    if state.user_id == user_id do
      if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, state.channel), %{}), state.user_id) do
        LiaisonServerWeb.Endpoint.broadcast("user:" <> state.user_id, "event", %{"type" => type, "payload" => event})
      else
        {:error, :disconnect}
      end
    else
      :ok
    end
  end

end
