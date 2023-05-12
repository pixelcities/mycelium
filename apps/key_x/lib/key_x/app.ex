defmodule KeyX.App do
  use Commanded.Application,
    otp_app: :key_x,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: KeyX.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Application.compile_env!(:key_x, :backend_config)[:backend_app] == __MODULE__ do
    router KeyX.Router
  end
end
