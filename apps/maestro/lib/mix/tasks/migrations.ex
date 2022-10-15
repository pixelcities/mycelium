defmodule Mix.Tasks.Migrations do
  @moduledoc """
  Call the release migration from mix
  """

  use Mix.Task

  @shortdoc "Run ecto migrations"

  @doc false
  def run(_args) do
    Maestro.Release.migrate()
  end
end

