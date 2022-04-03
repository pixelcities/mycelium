defmodule KeyX.Application do
  @moduledoc false

  @parent_module __MODULE__ |> Module.split |> Enum.drop(-1) |> Module.concat

  use Application

  @impl true
  def start(_type, _args) do
    app = get_app()
    tenants = Landlord.Registry.get()

    children = if app == @parent_module.App do
      Enum.flat_map(tenants, fn tenant ->
        [
          {KeyX.App, name: Module.concat([app, tenant]), tenant: tenant}
        ]
      end) ++ [
        {KeyX.Supervisor, backend: app, tenants: tenants}
      ]
    else
      []
    end

    opts = [strategy: :one_for_one, name: KeyX.ApplicationSupervisor]
    Supervisor.start_link(children, opts)
  end

  def get_app() do
    Application.fetch_env!(:key_x, :backend_config)[:backend_app]
  end
end
