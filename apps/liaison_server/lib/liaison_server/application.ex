defmodule LiaisonServer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    tenants = Landlord.Registry.get()

    self =
      Enum.flat_map(tenants, fn tenant ->

        # TODO: just use the tenant name directly
        application = Module.concat([LiaisonServer.App, tenant])

        [
          {LiaisonServer.App, name: application, tenant: tenant}
        ]
      end)

    dynamic = [
      {DynamicSupervisor, name: LiaisonServer.RelayEventSupervisor, strategy: :one_for_one}
    ]

    # We manage the supervisors for our children because they depend on our main app
    deps = [
      {MetaStore.Supervisor, backend: LiaisonServer.App, tenants: tenants},
      {DataStore.Supervisor, backend: LiaisonServer.App, tenants: tenants},
      {KeyX.Supervisor, backend: LiaisonServer.App, tenants: tenants},
      {Landlord.Supervisor, backend: LiaisonServer.App, tenants: tenants}
    ]

    children = [
      {Phoenix.PubSub, name: LiaisonServer.PubSub},
      LiaisonServerWeb.Presence,
      LiaisonServerWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: LiaisonServer.Supervisor]
    Supervisor.start_link(self ++ dynamic ++ deps ++ children, opts)
  end

end
