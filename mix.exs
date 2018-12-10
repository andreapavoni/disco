defmodule Disco.MixProject do
  use Mix.Project

  def project do
    [
      app: :disco,
      description: description(),
      package: package(),
      version: "0.1.2",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      # docs
      name: "Disco",
      source_url: "https://github.com/andreapavoni/disco",
      homepage_url: "https://github.com/andreapavoni/disco",
      docs: docs(),

      # dev/test
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.json": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      dialyzer: [plt_add_deps: :apps_direct]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :runtime_tools],
      mod: {Disco.Application, []}
    ]
  end

  defp description() do
    "Simple, opinionated library to build CQRS/ES driven systems."
  end

  defp package() do
    [
      maintainers: ["andreapavoni"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/andreapavoni/disco"}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ecto, "~> 3.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14"},
      {:jason, "~> 1.1"},
      {:uuid, "~> 1.1"},
      {:vex, "~> 0.8.0"},
      {:exconstructor, "~> 1.1.0"},

      # test
      {:mox, "~> 0.4", only: :test},
      {:ex_machina, "~> 2.2", only: :test},

      # code quality
      {:dialyxir, "~> 1.0.0-rc.4", only: [:dev], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:credo, "~> 1.0", only: [:dev, :test], runtime: false},

      # docs
      case System.version() |> Version.match?("~> 1.7.0") do
        true -> {:ex_doc, "~> 0.19", only: [:dev], runtime: false}
        false -> {:ex_doc, "~> 0.18.0", only: :dev, runtime: false}
      end
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs() do
    [
      # The main page in the docs
      main: "Disco",
      extras: ["README.md"]
    ]
  end
end
