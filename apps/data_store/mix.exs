defmodule DataStore.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_store,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
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
      mod: {DataStore.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},

      {:ecto_sql, "~> 3.0"},
      {:postgrex, ">= 0.0.0"},

      {:commanded, "~> 1.1"},
      {:commanded_ecto_projections, "~> 1.1"},
      {:commanded_eventstore_adapter, "~> 1.1"},
      {:eventstore, "~> 1.1"},

      {:ex_aws, "~> 2.2"},
      {:ex_aws_sts, "~> 2.2"},
      {:configparser_ex, "~> 4.0"},
      {:hackney, "~> 1.9"},
      {:sweet_xml, "~> 0.6"},

      {:core, "~> 0.1", in_umbrella: true},
      {:landlord, "~> 0.1", in_umbrella: true},
      {:meta_store, "~> 0.1", in_umbrella: true}
    ]
  end
end
