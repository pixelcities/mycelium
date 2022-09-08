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
    Events.DataURICreated,
    Events.MetadataCreated,
    Events.MetadataUpdated,
    Events.UserCreated,
    Events.UserUpdated,
    Events.CollectionCreated,
    Events.CollectionUpdated,
    Events.CollectionSchemaUpdated,
    Events.CollectionPositionSet,
    Events.CollectionIsReadySet,
    Events.CollectionTargetAdded,
    Events.TransformerCreated,
    Events.TransformerUpdated,
    Events.TransformerPositionSet,
    Events.TransformerTargetAdded,
    Events.TransformerInputAdded,
    Events.TransformerWALUpdated
  ]

  @spec handle(binary, binary, binary) :: :ok | :error

  @events
  |> Enum.each(fn x ->
    defp handle(%unquote(x){} = event, _metadata, socket_ref) do
      %type{} = event

      socket_ref.push("history", %{"type" => type |> String.trim_leading("Elixir.Core.Events."), "payload" => event})

      :ok
    end
  end)

  defp handle(_event, _metadata, _socket_ref), do: :ok


  def replay_from(from, ds_id, socket_ref) do
    EventStore.stream_all_forward(from, name: Module.concat(EventStore, ds_id))
    |> Enum.reduce_while(:ok, fn event, acc ->
      case handle(event.data, event.metadata, socket_ref) do
        :ok -> {:cont, :ok}
        :error -> {:halt, :error}
      end
    end)
  end

end
