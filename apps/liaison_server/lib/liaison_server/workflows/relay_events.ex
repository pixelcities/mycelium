defmodule LiaisonServer.Workflows.RelayEvents do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :current

  @events [
    Core.Events.SourceCreated,
    Core.Events.SourceUpdated,
    Core.Events.SourceDeleted,
    Core.Events.DataURICreated,
    Core.Events.MetadataCreated,
    Core.Events.MetadataUpdated,
    Core.Events.ConceptCreated,
    Core.Events.ConceptUpdated,
    Core.Events.UserCreated,
    Core.Events.UserUpdated,
    Core.Events.CollectionCreated,
    Core.Events.CollectionUpdated,
    Core.Events.CollectionSchemaUpdated,
    Core.Events.CollectionPositionSet,
    Core.Events.CollectionIsReadySet,
    Core.Events.CollectionTargetAdded,
    Core.Events.CollectionTargetRemoved,
    Core.Events.CollectionDeleted,
    Core.Events.TransformerCreated,
    Core.Events.TransformerUpdated,
    Core.Events.TransformerPositionSet,
    Core.Events.TransformerTargetAdded,
    Core.Events.TransformerInputAdded,
    Core.Events.TransformerWALUpdated,
    Core.Events.TransformerDeleted,
    Core.Events.WidgetCreated,
    Core.Events.WidgetUpdated,
    Core.Events.WidgetPositionSet,
    Core.Events.WidgetInputAdded,
    Core.Events.WidgetDeleted
  ]


  @impl true
  def init(config) do
    {workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {ds_id, config} = Keyword.pop(config, :ds_id)
    name = Module.concat([__MODULE__, ds_id])

    config = Keyword.put_new(config, :state, %{channel: "ds:" <> (ds_id |> to_string()), user_id: user_id, workspace: workspace})
    config = Keyword.put_new(config, :name, name)

    {:ok, config}
  end

  @events
  |> Enum.each(fn x ->
    @impl true
    def handle(%unquote(x){} = event, metadata) do
      %{state: state, event_number: event_number} = metadata
      %type{} = event

      LiaisonServerWeb.Endpoint.broadcast(state.channel, "event", %{
        "id" => event_number,
        "type" => type |> to_string() |> String.trim_leading("Elixir.Core.Events."),
        "payload" => event
      })

      :ok
    end
  end)

end

