defmodule Landlord.App do
  use Commanded.Application,
    otp_app: :landlord,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: Landlord.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Application.compile_env!(:landlord, :backend_config)[:backend_app] == __MODULE__ do
    router Landlord.Router
  end
end
