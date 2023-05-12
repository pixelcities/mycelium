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
      elixir: "~> 1.13",
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
      {:commanded, "~> 1.4"},
      {:commanded_eventstore_adapter, "~> 1.4"},
      {:eventstore, "~> 1.4"},

      {:argon2_elixir, "~> 2.4"},
      {:ecto_sql, "~> 3.9"},
      {:jason, "~> 1.3"},
      {:postgrex, "~> 0.17"},
      {:req, "~> 0.3.0"},

      {:swoosh, "~> 1.7"},
      {:ex_aws, "~> 2.3"},
      {:sweet_xml, "~> 0.7"},
      {:hackney, "~> 1.18"},
      {:gen_smtp, "~> 1.2"},

      {:core, "~> 0.1", in_umbrella: true}
    ]
  end
end
