import Config

if config_env() == :prod do
  # Env vars
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("HOST") || "datagarden.app"
  port = String.to_integer(System.get_env("PORT") || "5000")

  content_secret_key_base =
    System.get_env("CONTENT_SECRET_KEY_BASE") ||
      raise """
      environment variable CONTENT_SECRET_KEY_BASE is missing.
      """

  content_host = System.get_env("CONTENT_HOST") || "datagarden.page"
  content_port = String.to_integer(System.get_env("CONTENT_PORT") || "5001")

  secret_key =
    System.get_env("SECRET_KEY") ||
      raise """
      environment variable SECRET_KEY is missing.
      Please add a 32 byte secret
      """

  pg_host = System.get_env("PGHOST") || "localhost"
  pg_port = String.to_integer(System.get_env("PGPORT") || "5432")
  pg_user = System.get_env("PGUSER") || "postgres"
  pg_password = System.get_env("PGPASSWORD")


  # Configs

  config :liaison_server, LiaisonServerWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base

  config :key_x, KeyX.TrialAgent,
    secret_key: secret_key

  config :liaison_server, LiaisonServer.EventStore,
    hostname: pg_host,
    port: pg_port,
    username: pg_user,
    password: pg_password

  config :content_server, ContentServerWeb.Endpoint,
    url: [host: content_host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: content_port],
    secret_key_base: content_secret_key_base

  config :content_server, ContentServer.Repo,
    hostname: pg_host,
    port: pg_port,
    username: pg_user,
    password: pg_password

  config :meta_store, MetaStore.Repo,
    hostname: pg_host,
    port: pg_port,
    username: pg_user,
    password: pg_password

  config :landlord, Landlord.Repo,
    hostname: pg_host,
    port: pg_port,
    username: pg_user,
    password: pg_password

  config :maestro, Maestro.Repo,
    hostname: pg_host,
    port: pg_port,
    username: pg_user,
    password: pg_password

  config :key_x, KeyX.Repo,
    hostname: pg_host,
    port: pg_port,
    username: pg_user,
    password: pg_password

end
