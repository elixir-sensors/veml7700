defmodule VEML7700.MixProject do
  use Mix.Project

  @version "0.1.2"
  @description "Use Vishay ambient light sensor VEML7700 in Elixir"
  @source_url "https://github.com/mnishiguchi/veml7700"
  @datasheet_url "https://www.vishay.com/docs/84286/veml7700.pdf"

  def project do
    [
      app: :veml7700,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(Mix.env()),
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
      },
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
  defp deps(env) when env in [:test, :dev] do
    [
      {:circuits_i2c, github: "elixir-circuits/circuits_i2c", override: true},
      {:circuits_sim, github: "elixir-circuits/circuits_sim"},
      {:credo, "~> 1.7", runtime: false},
      {:dialyxir, "~> 1.3", runtime: false}
    ]
  end

  defp deps(_env) do
    [
      {:circuits_i2c, "~> 2.0 or ~> 1.0 or ~> 0.3"},
      {:ex_doc, "~> 0.29", only: :docs, runtime: false}
    ]
  end

  defp elixirc_paths(env) when env in [:test, :dev], do: ["lib", "test/support"]
  defp elixirc_paths(_env), do: ["lib"]

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
      links: %{
        "GitHub" => @source_url,
        "Data sheet" => @datasheet_url
      }
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

  defp aliases do
    [
      lint: ["format", "deps.unlock --unused", "hex.outdated", "credo", "dialyzer"]
    ]
  end
end
