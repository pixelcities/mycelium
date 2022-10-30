defmodule Mix.Tasks.ContentServer.Migrations do
  @moduledoc """
  Call the release migration from mix
  """

  use Mix.Task

  @shortdoc "Run ecto migrations"

  @doc false
  def run(_args) do
    ContentServer.Release.migrate()
  end
end
