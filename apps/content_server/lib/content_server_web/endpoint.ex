defmodule ContentServerWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :content_server

  @session_options [
    store: :ets,
    key: "_user_content_sid",
    table: :session
  ]

  socket "/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]]

  plug Plug.Static,
    at: "/",
    from: :content_server,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt)

  plug Plug.RequestId
  plug Plug.MethodOverride
  plug Plug.Head
  plug CORSPlug
  plug Plug.Session, @session_options

  plug ContentServerWeb.Router

  def init(_key, config) do
    :ets.new(:session, [:named_table, :public, read_concurrency: true])

    if config[:load_from_system_env] do
      port = System.get_env("CONTENT_PORT") || raise "expected the CONTENT_PORT environment variable to be set"
      {:ok, Keyword.put(config, :http, [:inet6, port: port])}
    else
      {:ok, config}
    end
  end
end
