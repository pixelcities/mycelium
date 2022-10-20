defmodule Mix.Tasks.KeyX.Migrations do
  @moduledoc """
  Call the release migration from mix
  """

  use Mix.Task

  @shortdoc "Run ecto migrations"

  @doc false
  def run(_args) do
    KeyX.Release.migrate()
  end
end

