defmodule Mycelium.MixProject do
  use Mix.Project

  def project do
    [
      apps_path: "apps",
      version: "0.2.10",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        mycelium: [
          include_executables_for: [:unix],
          applications: [
            content_server: :permanent,
            data_store: :permanent,
            key_x: :permanent,
            landlord: :permanent,
            liaison_server: :permanent,
            maestro: :permanent,
            meta_store: :permanent
          ]
        ]
      ]
    ]
  end

  # Dependencies listed here are available only for this
  # project and cannot be accessed from applications inside
  # the apps folder.
  #
  # Run "mix help deps" for examples and options.
  defp deps do
    [
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev], runtime: false}
    ]
  end

end
