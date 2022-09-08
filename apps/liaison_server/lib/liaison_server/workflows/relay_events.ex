defmodule LiaisonServer.Workflows.RelayEvents do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :current

  @events [
    Core.Events.SourceCreated,
    Core.Events.SourceUpdated,
    Core.Events.DataURICreated,
    Core.Events.MetadataCreated,
    Core.Events.MetadataUpdated,
    Core.Events.UserCreated,
    Core.Events.UserUpdated,
    Core.Events.CollectionCreated,
    Core.Events.CollectionUpdated,
    Core.Events.CollectionSchemaUpdated,
    Core.Events.CollectionPositionSet,
    Core.Events.CollectionIsReadySet,
    Core.Events.CollectionTargetAdded,
    Core.Events.TransformerCreated,
    Core.Events.TransformerUpdated,
    Core.Events.TransformerPositionSet,
    Core.Events.TransformerTargetAdded,
    Core.Events.TransformerInputAdded,
    Core.Events.TransformerWALUpdated
  ]


  @impl true
  def init(config) do
    {workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {ds_id, config} = Keyword.pop(config, :ds_id)
    {socket_ref, config} = Keyword.pop(config, :socket_ref)
    name = Module.concat([__MODULE__, ds_id])

    config = Keyword.put_new(config, :state, %{ds_id: ds_id, user_id: user_id, workspace: workspace, socket_ref: socket_ref})
    config = Keyword.put_new(config, :name, name)

    {:ok, config}
  end

  @events
  |> Enum.each(fn x ->
    @impl true
    def handle(%unquote(x){} = event, metadata) do
      %{state: state, event_number: event_number} = metadata
      %type{} = event

      LiaisonServerWeb.Endpoint.broadcast("ds:" <> state.ds_id, "event", %{
        "id" => event_number,
        "type" => type |> String.trim_leading("Elixir.Core.Events."),
        "payload" => event
      })

      :ok
    end
  end)

end

