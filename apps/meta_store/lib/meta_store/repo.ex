defmodule MetaStore.Repo do
  use Ecto.Repo,
    otp_app: :meta_store,
    adapter: Ecto.Adapters.Postgres
end
