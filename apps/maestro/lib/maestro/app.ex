defmodule Maestro.App do
  use Commanded.Application,
    otp_app: :maestro,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: Maestro.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Application.fetch_env!(:maestro, :backend_config)[:backend_app] == __MODULE__ do
    router Maestro.Router
  end
end
