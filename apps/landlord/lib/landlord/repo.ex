defmodule Landlord.Repo do
  use Ecto.Repo,
    otp_app: :landlord,
    adapter: Ecto.Adapters.Postgres
end
