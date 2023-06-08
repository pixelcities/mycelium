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
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
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

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:commanded, "~> 1.4"},
      {:commanded_ecto_projections, "~> 1.3"},
      {:commanded_eventstore_adapter, "~> 1.4"},
      {:eventstore, "~> 1.4"},
      {:ecto_sql, "~> 3.9"},
      {:jason, "~> 1.3"},
      {:postgrex, "~> 0.16"},
      {:rustler, "~> 0.25"},

      {:pg_test_case, "~> 0.1", only: :test},

      {:core, "~> 0.1", in_umbrella: true},
      {:landlord, "~> 0.1", in_umbrella: true}
    ]
  end

end
