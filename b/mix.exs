defmodule B.MixProject do
  use Mix.Project

  def project do
    [
      app: :b,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {B.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "3.7.2"},
      {:ecto_sqlite3, "~> 0.7"},
      {:exqlite, "~> 0.11"}
    ]
  end
end
