defmodule ContentServer.Repo do
  use Ecto.Repo,
    otp_app: :content_server,
    adapter: Ecto.Adapters.Postgres
end
