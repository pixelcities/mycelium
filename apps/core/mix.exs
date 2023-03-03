defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
      version: "0.1.0",
      build_path: "../../_build",
      config_path: "../../config/config.exs",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:commanded, "~> 1.4"},
      {:commanded_messaging, "~> 0.2"},
      {:elixir_uuid, "~> 1.2"},
      {:jason, "~> 1.3"},

      {:swoosh, "~> 1.7"},
      {:ex_aws, "~> 2.3"},
      {:sweet_xml, "~> 0.7"},
      {:hackney, "~> 1.18"},
      {:gen_smtp, "~> 1.2"}
    ]
  end
end
