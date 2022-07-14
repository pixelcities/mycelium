defmodule Landlord.MixProject do
  use Mix.Project

  def project do
    [
      app: :landlord,
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
      mod: {Landlord.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:argon2_elixir, "~> 2.0"},
      {:ecto_sql, "~> 3.6"},
      {:jason, "~> 1.1"},
      {:postgrex, ">= 0.0.0"},
      {:swoosh, "~> 1.7.3"},
      {:ex_aws, "~> 2.2"},
      {:sweet_xml, "~> 0.6"},
      {:hackney, "~> 1.9"},
      {:gen_smtp, "~> 1.0"},
      {:commanded, "~> 1.1"},
      {:commanded_eventstore_adapter, "~> 1.1"},
      {:eventstore, "~> 1.1"},

      {:core, "~> 0.1", in_umbrella: true}
    ]
  end
end
