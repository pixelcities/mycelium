defmodule LiaisonServer.EventHistory do
  @moduledoc """
  Event playback module

  Streams all specified events to a single socket. This is a one time effort
  and does not create a subscription.

  TODO: Add a reducer to filter duplicate events
  """

  alias LiaisonServer.EventStore
  alias Core.Events

  @events [
    Events.SourceCreated,
    Events.SourceUpdated,
    Events.SourceDeleted,
    Events.DataURICreated,
    Events.MetadataCreated,
    Events.MetadataUpdated,
    Events.ConceptCreated,
    Events.ConceptUpdated,
    Events.UserCreated,
    Events.UserUpdated,
    Events.CollectionCreated,
    Events.CollectionUpdated,
    Events.CollectionSchemaUpdated,
    Events.CollectionColorSet,
    Events.CollectionPositionSet,
    Events.CollectionIsReadySet,
    Events.CollectionTargetAdded,
    Events.CollectionTargetRemoved,
    Events.CollectionDeleted,
    Events.TransformerCreated,
    Events.TransformerUpdated,
    Events.TransformerPositionSet,
    Events.TransformerIsReadySet,
    Events.TransformerErrorSet,
    Events.TransformerTargetAdded,
    Events.TransformerInputAdded,
    Events.TransformerWALUpdated,
    Events.TransformerDeleted,
    Events.WidgetCreated,
    Events.WidgetUpdated,
    Events.WidgetPositionSet,
    Events.WidgetIsReadySet,
    Events.WidgetInputAdded,
    Events.WidgetSettingPut,
    Events.WidgetPublished,
    Events.WidgetDeleted,
    Events.ContentCreated,
    Events.ContentUpdated,
    Events.ContentDraftUpdated,
    Events.ContentDeleted,
    Events.PageCreated,
    Events.PageUpdated,
    Events.PageOrderSet,
    Events.PageDeleted
  ]

  @spec handle(binary, binary, binary) :: :ok | :error

  @events
  |> Enum.each(fn x ->
    defp handle(%unquote(x){} = event, _metadata, user_id) do
      %type{} = event

      LiaisonServerWeb.Endpoint.broadcast("user:" <> user_id, "history", %{"type" => type |> to_string() |> String.trim_leading("Elixir.Core.Events."), "payload" => event})

      :ok
    end
  end)

  defp handle(_event, _metadata, _user_id), do: :ok


  def replay_from(from, ds_id, user_id) do
    max_event_number =
      EventStore.stream_all_backward(-1, name: Module.concat(EventStore, ds_id))
      |> Enum.take(1)
      |> Enum.at(0, %{})
      |> Map.get(:event_number, 0)

    if from <= max_event_number do
      # TODO: Return event number as final message
      EventStore.stream_all_forward(from, name: Module.concat(EventStore, ds_id))
      |> Enum.reduce_while(:ok, fn event, _ ->
        case handle(event.data, event.metadata, user_id) do
          :ok -> {:cont, :ok}
          :error -> {:halt, :error}
        end
      end)

      :ok
    else
      :error
    end
  end

end
