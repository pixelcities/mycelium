import Config

config :ex_aws,
  access_key_id: [{:system, "AWS_ACCESS_KEY_ID"}, :instance_role],
  secret_access_key: [{:system, "AWS_SECRET_ACCESS_KEY"}, :instance_role],
  region: "eu-west-1",
  awscli_auth_adapter: ExAws.STS.AuthCache.AssumeRoleCredentialsAdapter

config :phoenix, :json_library, Jason

config :cors_plug,
  origin: ["https://datagarden.app"]


config :core, Core,
  from: [
    scheme: "https",
    host: "datagarden.app"
  ]


# LiaisonServer
config :liaison_server, LiaisonServer.EventStore,
  serializer: Commanded.Serialization.JsonSerializer,
  database: "eventstore",
  pool_size: 10

config :liaison_server, LiaisonServerWeb.Endpoint,
  debug_errors: false,
  code_reloader: false,
  check_origin: true,
  watchers: [],
  server: true


# ContentServer
config :content_server, ContentServerWeb.Endpoint,
  debug_errors: false,
  code_reloader: false,
  check_origin: true,
  watchers: [],
  server: true

config :content_server, ContentServer.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :content_server, ContentServer.Repo,
  database: "content_server"

config :content_server, :backend_config,
  backend_app: LiaisonServer.App


# MetaStore
config :meta_store, MetaStore.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :meta_store, MetaStore.Repo,
  database: "meta_store"

config :meta_store, :backend_config,
  backend_app: LiaisonServer.App


# DataStore
config :data_store, DataStore.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]

config :data_store, DataStore.DataTokens,
  bucket: "pxc-collection-store",
  role_arn: "arn:aws:iam::120183265440:role/mycelium-s3-collection-manager",
  restrict_source_ip: true

config :data_store, :backend_config,
  backend_app: LiaisonServer.App


# Landlord
config :landlord, :backend_config,
  backend_app: LiaisonServer.App

config :landlord, Landlord.Mailer,
  adapter: Swoosh.Adapters.ExAwsAmazonSES

config :landlord, Landlord.Repo,
  database: "landlord"


# KeyX
config :key_x, :backend_config,
  backend_app: LiaisonServer.App

config :key_x, KeyX.Repo,
  database: "key_x"

# Maestro
config :maestro, :backend_config,
  backend_app: LiaisonServer.App

config :maestro, Maestro.Repo,
  database: "maestro"

