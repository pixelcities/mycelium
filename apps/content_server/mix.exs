defmodule ContentServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :content_server,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      xref: [exclude: [LiaisonServer.App]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ContentServer.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:commanded, "~> 1.3"},
      {:commanded_ecto_projections, "~> 1.2"},
      {:commanded_eventstore_adapter, "~> 1.2"},
      {:eventstore, "~> 1.3"},
      {:ecto_sql, "~> 3.6"},
      {:postgrex, "~> 0.16"},
      {:jason, "~> 1.3"},
      {:phoenix, "~> 1.6"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_view, "~> 0.17.5"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:gettext, "~> 0.18"},
      {:plug_cowboy, "~> 2.5"},
      {:cors_plug, "~> 2.0"},

      {:core, "~> 0.1", in_umbrella: true},
      {:landlord, "~> 0.1", in_umbrella: true},
      {:meta_store, "~> 0.1", in_umbrella: true}
    ]
  end
end
