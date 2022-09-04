defmodule LiaisonServer.Workflows.RelayTasks do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :origin

  alias Core.Events.{TaskAssigned, TaskCompleted}

  @impl true
  def init(config) do
    {_workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {_restart_from, config} = Keyword.pop(config, :restart_from)
    name = Module.concat([__MODULE__, user_id])

    config = Keyword.put_new(config, :state, %{user_id: user_id})
    config = Keyword.put_new(config, :name, name)

    {:ok, config}
  end

  @impl true
  def handle(%TaskAssigned{} = event, metadata) do
    %{state: state} = metadata

    if state.user_id == event.worker do
      if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, "user:" <> state.user_id), %{}), state.user_id) do
        LiaisonServerWeb.Endpoint.broadcast("user:" <> state.user_id, "event", %{"type" => "TaskAssigned", "payload" => event})

        :ok
      else
        DynamicSupervisor.terminate_child(LiaisonServer.RelayEventSupervisor, self())

        {:error, :disconnect}
      end
    else
      :ok
    end
  end

  @impl true
  def handle(%TaskCompleted{} = event, metadata) do
    %{state: state} = metadata

    if state.user_id == Map.get(metadata, "user_id") do
      if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, "user:" <> state.user_id), %{}), state.user_id) do
        LiaisonServerWeb.Endpoint.broadcast("user:" <> state.user_id, "event", %{"type" => "TaskCompleted", "payload" => event})

        :ok
      else
        DynamicSupervisor.terminate_child(LiaisonServer.RelayEventSupervisor, self())

        {:error, :disconnect}
      end
    else
      :ok
    end
  end

end
