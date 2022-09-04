defmodule LiaisonServer.Workflows.RelayEvents do
  use Commanded.Event.Handler,
    consistency: :eventual,
    start_from: :origin

  alias Core.Events.{
    SourceCreated,
    SourceUpdated,
    DataURICreated,
    MetadataCreated,
    MetadataUpdated,
    UserCreated,
    UserUpdated,
    CollectionCreated,
    CollectionUpdated,
    CollectionSchemaUpdated,
    CollectionPositionSet,
    CollectionIsReadySet,
    CollectionTargetAdded,
    TransformerCreated,
    TransformerUpdated,
    TransformerPositionSet,
    TransformerTargetAdded,
    TransformerInputAdded,
    TransformerWALUpdated
  }

  @impl true
  def init(config) do
    {workspace, config} = Keyword.pop(config, :workspace)
    {user_id, config} = Keyword.pop(config, :user_id)
    {restart_from, config} = Keyword.pop(config, :restart_from)
    name = Module.concat([__MODULE__, user_id])

    config = Keyword.put_new(config, :state, %{user_id: user_id, workspace: workspace, restart_from: restart_from})
    config = Keyword.put_new(config, :name, name)

    {:ok, config}
  end

  @impl true
  def handle(%SourceCreated{} = event, metadata), do: handle_event("SourceCreated", event, metadata)

  @impl true
  def handle(%SourceUpdated{} = event, metadata), do: handle_event("SourceUpdated", event, metadata)

  @impl true
  def handle(%DataURICreated{} = event, metadata), do: handle_event("DataURICreated", event, metadata)

  @impl true
  def handle(%MetadataCreated{} = event, metadata), do: handle_event("MetadataCreated", event, metadata)

  @impl true
  def handle(%MetadataUpdated{} = event, metadata), do: handle_event("MetadataUpdated", event, metadata)

  @impl true
  def handle(%UserCreated{} = event, metadata), do: handle_event("UserCreated", event, metadata, true)

  @impl true
  def handle(%UserUpdated{} = event, metadata), do: handle_event("UserUpdated", event, metadata, true)

  @impl true
  def handle(%CollectionCreated{} = event, metadata), do: handle_event("CollectionCreated", event, metadata)

  @impl true
  def handle(%CollectionUpdated{} = event, metadata), do: handle_event("CollectionUpdated", event, metadata)

  @impl true
  def handle(%CollectionSchemaUpdated{} = event, metadata), do: handle_event("CollectionSchemaUpdated", event, metadata)

  @impl true
  def handle(%CollectionPositionSet{} = event, metadata), do: handle_event("CollectionPositionSet", event, metadata)

  @impl true
  def handle(%CollectionIsReadySet{} = event, metadata), do: handle_event("CollectionIsReadySet", event, metadata)

  @impl true
  def handle(%CollectionTargetAdded{} = event, metadata), do: handle_event("CollectionTargetAdded", event, metadata)

  @impl true
  def handle(%TransformerCreated{} = event, metadata), do: handle_event("TransformerCreated", event, metadata)

  @impl true
  def handle(%TransformerUpdated{} = event, metadata), do: handle_event("TransformerUpdated", event, metadata)

  @impl true
  def handle(%TransformerPositionSet{} = event, metadata), do: handle_event("TransformerPositionSet", event, metadata)

  @impl true
  def handle(%TransformerTargetAdded{} = event, metadata), do: handle_event("TransformerTargetAdded", event, metadata)

  @impl true
  def handle(%TransformerInputAdded{} = event, metadata), do: handle_event("TransformerInputAdded", event, metadata)

  @impl true
  def handle(%TransformerWALUpdated{} = event, metadata), do: handle_event("TransformerWALUpdated", event, metadata)


  # TODO: send event to a reducer, which can be called on startup to get old messages
  defp handle_event(type, event, metadata, all_workspaces \\ false) do
    %{state: state, event_number: event_number} = metadata

    if event_number >= state.restart_from && (all_workspaces || state.workspace == event.workspace) do
      if Map.has_key?(Enum.into(Phoenix.Tracker.list(LiaisonServerWeb.Tracker, "user:" <> state.user_id), %{}), state.user_id) do
        LiaisonServerWeb.Endpoint.broadcast("user:" <> state.user_id, "event", %{"id" => event_number, "type" => type, "payload" => event})

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

