defmodule Maestro.App do
  use Commanded.Application,
    otp_app: :maestro,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: Maestro.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Maestro.Application.get_app() == __MODULE__ do
    router Maestro.Router
  end
end
