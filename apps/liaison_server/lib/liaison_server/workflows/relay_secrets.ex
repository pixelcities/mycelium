defmodule LiaisonServer.Workflows.RelaySecrets do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :origin

  alias Core.Events.SecretShared

  @impl true
  def init(config) do
    {_workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    name = Module.concat([__MODULE__, user_id])

    config = Keyword.put_new(config, :state, %{user_id: user_id})
    config = Keyword.put_new(config, :name, name)
    config = Keyword.put_new(config, :subscribe_to, "secrets-" <> user_id)

    {:ok, config}
  end

  @impl true
  def handle(%SecretShared{} = event, metadata) do
    %{state: state} = metadata

    if Map.has_key?(LiaisonServerWeb.Presence.list("user:" <> state.user_id), state.user_id) do
      LiaisonServerWeb.Endpoint.broadcast("user:" <> state.user_id, "event", %{"type" => "SecretShared", "payload" => event})

      :ok
    else
      DynamicSupervisor.terminate_child(LiaisonServer.RelayEventSupervisor, self())

      {:error, :disconnect}
    end
  end

end
