defmodule Maestro.Repo do
  use Ecto.Repo,
    otp_app: :maestro,
    adapter: Ecto.Adapters.Postgres
end
