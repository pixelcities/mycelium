defmodule MetaStore.App do
  use Commanded.Application,
    otp_app: :meta_store,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: MetaStore.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Application.compile_env!(:meta_store, :backend_config)[:backend_app] == __MODULE__ do
    router MetaStore.Router
  end
end
