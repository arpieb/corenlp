defmodule CoreNLP.Mixfile do
  use Mix.Project

  def project do
    [
      app: :corenlp,
      version: "0.1.0",
      elixir: "~> 1.4",
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      description: description(),
      package: package(),

      # Docs.
      name: "CoreNLP",
      source_url: "https://github.com/arpieb/corenlp",
      homepage_url: "https://github.com/arpieb/corenlp",
      docs: [
        main: "readme",
        extras: [
          "README.md",
        ]
      ]
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ex_doc, "~> 0.15.0", only: :dev},
      {:httpoison, "~> 0.11.0"},
      {:poison, "~> 3.1"},
    ]
  end

  defp description do
    """
    This package provides a client interface to a Stanford CoreNLP Server.
    """
  end

  defp package do
    [
      files: [
        "lib",
        "mix.exs",
        "README*",
        "LICENSE*",
      ],
      maintainers: ["Robert Bates"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => "https://github.com/arpieb/corenlp",
        "CoreNLP" => "http://stanfordnlp.github.io/CoreNLP/index.html",
      },
    ]
  end
end
