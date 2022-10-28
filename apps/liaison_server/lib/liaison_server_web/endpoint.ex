defmodule LiaisonServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :liaison_server

  @session_options [
    store: :cookie,
    key: "_mycelium_key",
    same_site: "Strict",
    secure: true,
    signing_salt: "NczsXZX+"
  ]

  socket "/socket", LiaisonServerWeb.UserSocket,
    websocket: true,
    longpoll: false

  plug Plug.RequestId

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head
  plug CORSPlug
  plug Plug.Session, @session_options
  plug LiaisonServerWeb.Router

  def init(_key, config) do
    if config[:load_from_system_env] do
      port = System.get_env("PORT") || raise "expected the PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
