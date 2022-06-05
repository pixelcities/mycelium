defmodule Mix.Tasks.Trial.Init do
  @moduledoc """
  Create a data space managed by a (trial) agent
  """

  use Mix.Task

  @shortdoc "Initialize the data space and agent for a managed data space"

  @switches [
    name: :string
  ]

  @doc false
  def run(args) do
    {opts, _} = OptionParser.parse!(args, strict: @switches)

    name = Keyword.get(opts, :name)
    email = Application.get_env(:key_x, KeyX.TrialAgent)[:email]

    if not String.match?(name, ~r/^\w+$/) do
      Mix.raise("Missing or invalid name. Please specify a valid handle using --name")
    end

    {:ok, _} = Application.ensure_all_started(:landlord)
    {:ok, _} = Application.ensure_all_started(:key_x)

    {:ok, user} = Landlord.Accounts.create_agent(email)
    key_id = KeyX.TrialAgent.create_manifest_key()

    Landlord.Tenants.create_data_space(user, %{key_id: key_id, handle: name})
    LiaisonServer.Application.init_event_store!(name)
  end
end
