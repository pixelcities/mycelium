defmodule DataStore.App do
  use Commanded.Application,
    otp_app: :data_store,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: DataStore.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Application.fetch_env!(:data_store, :backend_config)[:backend_app] == __MODULE__ do
    router DataStore.Router
  end
end
