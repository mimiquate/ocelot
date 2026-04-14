defmodule Ocelot.MixProject do
  use Mix.Project

  def project do
    [
      app: :ocelot,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
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
      # Website
      {:plug, "~> 1.9"},
      {:jason, "~> 1.4"},

      # Oban
      {:oban, "~> 2.18"},

      # Dev
      {:bandit, "~> 1.6.0", only: [:dev]},
      {:ecto_sqlite3, "~> 0.18", only: [:dev]}
    ]
  end

  defp aliases do
    [
      dev: "run --no-halt dev.exs"
    ]
  end
end
