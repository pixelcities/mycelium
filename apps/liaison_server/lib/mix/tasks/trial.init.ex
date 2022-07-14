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

    if not String.match?(name, ~r/^\w+$/) do
      Mix.raise("Missing or invalid name. Please specify a valid handle using --name")
    end

    LiaisonServer.Release.init_trial(name)
  end
end
