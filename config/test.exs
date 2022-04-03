use Mix.Config

config :liaison_server, LiaisonServer.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :meta_store, MetaStore.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :meta_store, :backend_config,
  backend_app: MetaStore.App
