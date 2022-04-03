defmodule LiaisonServer.App do
  use Commanded.Application,
    otp_app: :liaison_server,
     event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: LiaisonServer.EventStore
    ]
  use Commanded.CommandDispatchValidation

  def init(config) do
    {tenant, config} = Keyword.pop(config, :tenant)

    # TODO: ensure that there is an eventstore schema for each tenant
    config =
      config
      |> put_in([:event_store, :name], Module.concat([LiaisonServer.EventStore, tenant]))
      |> put_in([:event_store, :prefix], "#{tenant}")

    {:ok, config}
  end

  router LiaisonServer.Router
end
