import Config

config :logger,
  level: :debug

config :ex_aws,
  secret_access_key: [{:awscli, "mycelium", 30}],
  access_key_id: [{:awscli, "mycelium", 30}],
  region: "eu-west-1",
  awscli_auth_adapter: ExAws.STS.AuthCache.AssumeRoleCredentialsAdapter

config :phoenix, :json_library, Jason

config :cors_plug,
  origin: ["http://localhost:3000"]


# Core
config :core, Core,
  from: [
    scheme: "http",
    host: "localhost",
    port: 3000
  ]


# LiaisonServer
config :liaison_server, LiaisonServer.EventStore,
  serializer: Commanded.Serialization.JsonSerializer,
  username: "postgres",
  database: "eventstore",
  hostname: "localhost",
  pool_size: 10

config :liaison_server, LiaisonServerWeb.Endpoint,
  http: [port: 5000],
  debug_errors: true,
  code_reloader: false,
  check_origin: false,
  watchers: [],
  server: true


# ContentServer
config :content_server, ContentServerWeb.Endpoint,
  http: [port: 5001],
  debug_errors: true,
  code_reloader: false,
  check_origin: false,
  watchers: [
    node: ["build.js", "--watch", cd: Path.expand("../apps/content_server/assets", __DIR__)],
    sass: {
      DartSass,
      :install_and_run,
      [:default, ~w(--no-source-map --watch)]
    }
  ],
  server: true

config :content_server, ContentServer.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :content_server, ContentServer.Repo,
  database: "content_server",
  username: "postgres",
  hostname: "localhost"

config :content_server, :backend_config,
  backend_app: LiaisonServer.App


# MetaStore
config :meta_store, MetaStore.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :meta_store, MetaStore.Repo,
  database: "meta_store",
  username: "postgres",
  hostname: "localhost"

config :meta_store, :backend_config,
  backend_app: LiaisonServer.App


# DataStore
config :data_store, DataStore.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :data_store, DataStore.Data,
  bucket: "pxc-collection-store",
  restrict_source_ip: false

config :data_store, :backend_config,
  backend_app: LiaisonServer.App


# Landlord
config :landlord, :backend_config,
  backend_app: LiaisonServer.App

config :landlord, Landlord.Repo,
  database: "landlord",
  username: "postgres",
  hostname: "localhost"

config :landlord, Landlord.Mailer,
  adapter: Swoosh.Adapters.Local

config :landlord, :subscriptions, enabled: false
config :landlord, Landlord.Tenants.SubscriptionApi,
  basepath: "https://sandbox-vendors.paddle.com",
  checkout_uri: "http://localhost:3001"


# KeyX
config :key_x, :backend_config,
  backend_app: LiaisonServer.App

config :key_x, KeyX.Repo,
  database: "key_x",
  username: "postgres",
  hostname: "localhost"


# Maestro
config :maestro, :backend_config,
  backend_app: LiaisonServer.App

config :maestro, Maestro.Repo,
  database: "maestro",
  username: "postgres",
  hostname: "localhost"


import_config "dev.secret.exs"
