defmodule KeyX.MixProject do
  use Mix.Project

  def project do
    [
      app: :key_x,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [LiaisonServer.App]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {KeyX.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto_sql, "~> 3.6"},
      {:jason, "~> 1.1"},
      {:postgrex, ">= 0.0.0"},
      {:commanded, "~> 1.1"},
      {:commanded_eventstore_adapter, "~> 1.1"},
      {:eventstore, "~> 1.1"},
      {:rustler, "~> 0.25.0"},

      {:core, "~> 0.1", in_umbrella: true},
      {:landlord, "~> 0.1", in_umbrella: true}
    ]
  end

end
