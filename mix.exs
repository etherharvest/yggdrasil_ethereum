defmodule YggdrasilEthereum.MixProject do
  use Mix.Project

  @version "0.1.0"
  @root "https://github.com/etherharvest/yggdrasil_ethereum"

  def project do
    [
      app: :yggdrasil_ethereum,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      deps: deps(),
      docs: docs()
    ]
  end

  #############
  # Application

  defp elixirc_paths(:test) do
    ["lib", "deps/eth_event/test/support"]
  end
  defp elixirc_paths(_) do
    ["lib"]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Yggdrasil.Ethereum.Application, []}
    ]
  end

  defp deps do
    [
      {:yggdrasil, "~> 4.1"},
      {:eth_event, "~> 0.1"},
      {:uuid, "~> 1.1", only: [:dev, :test]},
      {:ex_doc, "~> 0.18.4", only: :dev},
      {:credo, "~> 0.10", only: :dev}
    ]
  end

  #########
  # Package

  defp package do
    [
      description: "Ethereum events adapter for Yggdrasil (pub/sub)",
      files: ["lib", "mix.exs", "images", "README.md", "test/support"],
      maintainers: ["Alexander de Sousa"],
      licenses: ["MIT"],
      links: %{
        "Github" => @root
      }
    ]
  end

  ###############
  # Documentation

  defp docs do
    [
      source_url: @root,
      source_ref: "v#{@version}",
      main: Yggdrasil.Ethereum.Application,
      formatters: ["html"],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "Application": [
        Yggdrasil.Ethereum.Application
      ],
      "Adapter": [
        Yggdrasil.Settings.Ethereum,
        Yggdrasil.Adapter.Ethereum
      ],
      "Subscriber adapter": [
        Yggdrasil.Subscriber.Adapter.Ethereum
      ],
    ]
  end
end
