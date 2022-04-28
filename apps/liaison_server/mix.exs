defmodule LiaisonServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :liaison_server,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LiaisonServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:commanded, "~> 1.1"},
      {:commanded_ecto_projections, "~> 1.1"},
      {:commanded_eventstore_adapter, "~> 1.1"},
      {:eventstore, "~> 1.1"},
      {:jason, "~> 1.1"},
      {:phoenix, "~> 1.6"},
      {:plug_cowboy, "~> 2.5"},
      {:cors_plug, "~> 2.0"},

      {:core, "~> 0.1", in_umbrella: true},
      {:meta_store, "~> 0.1", in_umbrella: true},
      {:data_store, "~> 0.1", in_umbrella: true},
      {:landlord, "~> 0.1", in_umbrella: true},
      {:key_x, "~> 0.1", in_umbrella: true},
      {:maestro, "~> 0.1", in_umbrella: true}
    ]
  end
end
