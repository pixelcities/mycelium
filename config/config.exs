import Config

config :hammer,
  backend: {Hammer.Backend.ETS, [
    expiry_ms: 60_000 * 60 * 4,
    cleanup_interval_ms: 60_000 * 10
  ]}

config :liaison_server, event_stores: [LiaisonServer.EventStore]
config :liaison_server, LiaisonServerWeb.Endpoint,
  url: [host: "localhost"],
  pubsub_server: LiaisonServer.PubSub

config :content_server, event_stores: [ContentServer.EventStore]
config :content_server, ContentServerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: ContentServerWeb.ErrorView, accepts: ~w(html), layout: false],
  pubsub_server: ContentServer.PubSub,
  live_view: [signing_salt: "S8rBddln"]
config :content_server, ecto_repos: [ContentServer.Repo]

config :meta_store, event_stores: [MetaStore.EventStore]
config :meta_store, ecto_repos: [MetaStore.Repo]

config :data_store, event_stores: [DataStore.EventStore]

config :landlord, ecto_repos: [Landlord.Repo]

config :key_x, ecto_repos: [KeyX.Repo]
config :key_x, KeyX.TrialAgent,
  email: "hello@pixelcities.io",
  key_id: "633e6f89-3530-41c0-a7dc-7ce6d586f832"

config :maestro, event_stores: [Maestro.EventStore]
config :maestro, ecto_repos: [Maestro.Repo]

config :esbuild,
  version: "0.14.29",
  content_server: [
    args:
      ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
    cd: Path.expand("../apps/content_server/assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

import_config "#{Mix.env()}.exs"

