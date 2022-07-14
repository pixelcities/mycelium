defmodule LiaisonServer.Release do
  @app :liaison_server

  def create_event_store do
    {:ok, _} = Application.ensure_all_started(:postgrex)
    {:ok, _} = Application.ensure_all_started(:ssl)

    :ok = Application.load(@app)

    config = LiaisonServer.EventStore.config()

    :ok = EventStore.Tasks.Create.exec(config, [])
  end

  def init_trial(name) do
    {:ok, _} = Application.ensure_all_started(:landlord)
    {:ok, _} = Application.ensure_all_started(:key_x)

    email = Application.get_env(:key_x, KeyX.TrialAgent)[:email]

    {:ok, user} = Landlord.Accounts.create_agent(email)
    key_id = KeyX.TrialAgent.create_manifest_key()

    Landlord.Tenants.create_data_space(user, %{key_id: key_id, handle: name})
    LiaisonServer.Application.init_event_store!(name)
  end
end
