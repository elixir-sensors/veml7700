defmodule VEML7700.MixProject do
  use Mix.Project

  @version "0.1.0"
  @description "Use Vishay VEML6030 and VEML7700 sensors in Elixir"
  @source_url "https://github.com/mnishiguchi/veml7700"

  def project do
    [
      app: :veml7700,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      start_permanent: Mix.env() == :prod,
      description: @description,
      dialyzer: [
        flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
      ],
      docs: docs(),
      package: package(),
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
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
      {:circuits_i2c,
       [
         only: [:dev, :test],
         env: :prod,
         git: "https://github.com/elixir-circuits/circuits_i2c.git",
         branch: "configurable-backend",
         override: true
       ]},
      {:ex_doc, "~> 0.29", only: :docs, runtime: false},
      {:dialyxir, "~> 1.3", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:circuits_sim, github: "elixir-circuits/circuits_sim", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      files: [
        "lib",
        "test",
        "mix.exs",
        "README*",
        "LICENSE*",
        "CHANGELOG*"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    }
  end

  defp docs do
    [
      extras: ["README.md", "CHANGELOG.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"]
    ]
  end
end
