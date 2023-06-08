defmodule Core.Events.SecretShared do
  use Commanded.Event,
    version: 2,
    from: Core.Commands.ShareSecret,
    with: [:date, :message_id]

  defimpl Commanded.Event.Upcaster do
    def upcast(%{version: 1} = event, _metadata) do
      Core.Events.SecretShared.new(event, message_id: 0, version: 2)
    end

    def upcast(event, _metadata), do: event
  end
end
