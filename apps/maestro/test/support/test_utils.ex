defmodule Maestro.TestUtils do

  def create_events(application, stream_id, version, events) do
    event_data = Enum.map(events, fn event ->
      %Commanded.EventStore.EventData{
        causation_id: UUID.uuid4(),
        correlation_id: UUID.uuid4(),
        event_type: Commanded.EventStore.TypeProvider.to_string(event),
        data: event,
        metadata: %{},
      }
    end)

    Commanded.EventStore.append_to_stream(application, stream_id, version, event_data)
  end
end
