import Config

config :liaison_server, event_stores: [LiaisonServer.EventStore]
config :liaison_server, LiaisonServerWeb.Endpoint,
  url: [host: "localhost"],
  pubsub_server: LiaisonServer.PubSub

config :meta_store, event_stores: [MetaStore.EventStore]
config :meta_store, ecto_repos: [MetaStore.Repo]

config :data_store, event_stores: [DataStore.EventStore]

config :landlord, ecto_repos: [Landlord.Repo]

config :key_x, ecto_repos: [KeyX.Repo]

config :maestro, event_stores: [Maestro.EventStore]

import_config "#{Mix.env()}.exs"

