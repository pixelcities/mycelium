defmodule ContentServer.App do
  use Commanded.Application,
    otp_app: :content_server,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: ContentServer.EventStore
    ]
  use Commanded.CommandDispatchValidation

  if Application.compile_env!(:content_server, :backend_config)[:backend_app] == __MODULE__ do
    router ContentServer.Router
  end
end
