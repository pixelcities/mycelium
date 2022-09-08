defmodule LiaisonServer.Workflows.RelaySecrets do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :origin

  alias Core.Events.SecretShared

  @impl true
  def init(config) do
    {_workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {ds_id, config} = Keyword.pop(config, :ds_id)
    {socket_ref, config} = Keyword.pop(config, :socket_ref)
    name = Module.concat([__MODULE__, ds_id, user_id])

    config = Keyword.put_new(config, :state, %{ds_id: ds_id, user_id: user_id, socket_ref: socket_ref})
    config = Keyword.put_new(config, :name, name)
    config = Keyword.put_new(config, :subscribe_to, "secrets-" <> user_id)

    {:ok, config}
  end

  @impl true
  def handle(%SecretShared{} = event, metadata) do
    %{state: state} = metadata

    if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, "ds:" <> state.ds_id), %{}), state.user_id) do
      state.socket_ref.push("event", %{"type" => "SecretShared", "payload" => event})

      :ok
    else
      DynamicSupervisor.terminate_child(LiaisonServer.RelayEventSupervisor, self())

      {:error, :disconnect}
    end
  end

end
