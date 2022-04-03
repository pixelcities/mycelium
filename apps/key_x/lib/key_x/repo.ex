defmodule KeyX.Repo do
  use Ecto.Repo,
    otp_app: :key_x,
    adapter: Ecto.Adapters.Postgres
end
