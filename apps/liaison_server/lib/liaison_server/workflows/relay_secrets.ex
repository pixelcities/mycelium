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
    name = Module.concat([__MODULE__, ds_id, user_id])

    config = Keyword.put_new(config, :state, %{channel: "ds:" <> (ds_id |> to_string()), user_id: user_id})
    config = Keyword.put_new(config, :name, name)
    config = Keyword.put_new(config, :subscribe_to, "secrets-" <> user_id)

    {:ok, config}
  end

  @impl true
  def handle(%SecretShared{} = event, metadata) do
    %{state: state} = metadata

    if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, state.channel), %{}), state.user_id) do
      LiaisonServerWeb.Endpoint.broadcast("user:" <> state.user_id, "event", %{"type" => "SecretShared", "payload" => event})

      :ok
    else
      {:error, :disconnect}
    end
  end

end
